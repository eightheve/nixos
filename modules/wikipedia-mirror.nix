{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.site.modules.wikipediaMirror;
  topology = config.site.topology;

  # Fixed UID/GID so NFS squash mapping is consistent across SAOTOME and KAZOOIE.
  wikipediaUid = 4243;
  wikipediaGid = 4243;

  baseDir = "/srv/data/wikipedia";
  clientPath = "/srv/wikipedia";

  zimPattern = "wikipedia_en_all_nopic_[0-9]{4}-[0-9]{2}\\.zim";
  zimBaseUrl = "https://download.kiwix.org/zim/wikipedia";

  saotomeWgIp = topology.SAOTOME.wireguard.interfaces.wg0.ip;
  kazooieWgIp = topology.KAZOOIE.wireguard.interfaces.wg0.ip;

  mirrorScript = pkgs.writeShellScript "wikipedia-mirror" ''
    set -euo pipefail
    export PATH="${
      lib.makeBinPath [
        pkgs.curl
        pkgs.coreutils
        pkgs.gawk
        pkgs.gnugrep
      ]
    }"

    cd ${baseDir}

    echo "Fetching zim index..."
    index=$(curl -fsSL ${zimBaseUrl}/)

    newest=$(printf '%s' "$index" | grep -oE '${zimPattern}' | sort -u | tail -1)
    if [ -z "$newest" ]; then
      echo "No matching zim found in index" >&2
      exit 1
    fi
    # Snapshots are named by download date; $newest carries the release date.
    date=$(date +%F)
    echo "Newest zim: $newest (snapshot dir $date)"

    if [ -f "$date/$newest" ]; then
      echo "Already up to date."
    else
      expected=$(curl -fsSIL "${zimBaseUrl}/$newest" | grep -i '^content-length' | tail -1 | tr -d '\r' | awk '{print $2}')
      echo "Downloading $newest ($expected bytes)..."
      mkdir -p "$date"
      tmp="$date/.download.$newest"
      # Resumable: the timer kills the service after 1h; the next run resumes.
      curl -fSL --retry 5 --retry-connrefused -C - -o "$tmp" "${zimBaseUrl}/$newest"
      actual=$(stat -c %s "$tmp")
      if [ "$actual" != "$expected" ]; then
        echo "Size mismatch after download: $actual != $expected" >&2
        exit 1
      fi
      mv "$tmp" "$date/$newest"
      chmod 0644 "$date/$newest"
      echo "Download complete."
    fi

    # Relative symlink so it resolves through the NFS mount on KAZOOIE too.
    ln -sfn "$date" latest

    # Keep only the newest ${toString cfg.keep} dated directories.
    ls -1d [0-9]* 2>/dev/null | sort -r | tail -n +$((${toString cfg.keep} + 1)) | while read -r old; do
      echo "Pruning old snapshot $old"
      rm -rf "$old"
    done

    echo "Done."
  '';
in
{
  options.site.modules.wikipediaMirror = {
    server.enable = lib.mkEnableOption "weekly english wikipedia zim mirror on SAOTOME";
    client.enable = lib.mkEnableOption "wikipedia NFS client role (runs on KAZOOIE)";

    keep = lib.mkOption {
      type = lib.types.int;
      default = 5;
      description = "Number of dated snapshots to keep alongside the latest symlink.";
    };

    serve = {
      enable = lib.mkEnableOption "kiwix-serve for the latest wikipedia zim";

      bindAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = ''
          Address kiwix-serve binds to. Use the host's WireGuard IP to make it
          reachable for other hosts in the mesh (firewall then only allows the
          port on wg0).
        '';
      };

      port = lib.mkOption {
        type = lib.types.int;
        default = 8081;
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.server.enable || cfg.client.enable) {
      users.groups.wikipedia.gid = wikipediaGid;
      users.users.wikipedia = {
        uid = wikipediaUid;
        group = "wikipedia";
        isSystemUser = true;
        home = baseDir;
        createHome = false;
      };
    })

    (lib.mkIf cfg.server.enable {
      systemd.tmpfiles.rules = [
        "d ${baseDir} 0755 wikipedia wikipedia -"
      ];

      systemd.services.wikipedia-mirror = {
        description = "Download weekly english wikipedia zim snapshot";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          User = "wikipedia";
          Group = "wikipedia";
          # ~53GB at ~13MB/s; killed runs resume on the next trigger.
          TimeoutStartSec = "90min";
        };
        script = toString mirrorScript;
      };

      systemd.timers.wikipedia-mirror = {
        description = "Weekly wikipedia zim update";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "weekly";
          Persistent = true;
          RandomizedDelaySec = "6h";
        };
      };

      services.nfs.server = {
        enable = true;
        exports = ''
          ${baseDir} ${kazooieWgIp}/32(ro,sync,no_subtree_check,all_squash,anonuid=${toString wikipediaUid},anongid=${toString wikipediaGid})
        '';
      };

      networking.firewall.interfaces.wg0.allowedTCPPorts = [ 2049 ];
    })

    (lib.mkIf cfg.serve.enable {
      # Serves ${baseDir}/latest/ which is a relative symlink to the newest
      # dated snapshot; kiwix-serve follows it on restart. Full-text search
      # uses the index embedded in the zim, no extra setup.
      systemd.services.kiwix-serve = {
        description = "Serve wikipedia zim via kiwix-serve";
        after = [ "local-fs.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          User = "wikipedia";
          Group = "wikipedia";
          Restart = "on-failure";
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ReadOnlyPaths = [ baseDir ];
        };
        script = ''
          exec ${pkgs.kiwix-tools}/bin/kiwix-serve \
            --address=${cfg.serve.bindAddress} \
            --port=${toString cfg.serve.port} \
            ${baseDir}/latest/*.zim
        '';
      };

      networking.firewall.interfaces.wg0.allowedTCPPorts = [ cfg.serve.port ];
    })

    (lib.mkIf cfg.client.enable {
      fileSystems.${clientPath} = {
        device = "${saotomeWgIp}:${baseDir}";
        fsType = "nfs";
        options = [
          "nfsvers=4"
          "noatime"
          "x-systemd.automount"
          "x-systemd.idle-timeout=5min"
          "x-systemd.device-timeout=10s"
          "x-systemd.mount-timeout=10s"
          "nofail"
        ];
      };
    })
  ];
}
