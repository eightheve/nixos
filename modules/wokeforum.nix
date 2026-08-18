{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.site.modules.wokeforum;
  topology = config.site.topology;

  # Fixed UID/GID so file ownership is consistent across SAOTOME and KAZOOIE.
  wokestoryUid = 4242;
  wokestoryGid = 4242;

  serverPath = "/srv/data/wokestory";
  clientPath = "/srv/wokestory";

  saotomeWgIp = topology.SAOTOME.wireguard.interfaces.wg0.ip;
  kazooieWgIp = topology.KAZOOIE.wireguard.interfaces.wg0.ip;

  smfVersion = "2.1.7";

  smfSource = pkgs.fetchFromGitHub {
    owner = "SimpleMachines";
    repo = "SMF";
    rev = "v${smfVersion}";
    hash = "sha256-dLNwzOsXegb+bDK/MWnq6W7/AwHcOTMUVW2jV8ruqV8=";
  };

  smfVendor = pkgs.stdenv.mkDerivation {
    name = "smf-${smfVersion}-vendor";
    src = smfSource;
    nativeBuildInputs = [ pkgs.php.packages.composer ];
    buildPhase = ''
      composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs
    '';
    installPhase = ''
      cp -r vendor $out
    '';
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-B3bOnm8w44GCcNF97X09bqTlHpUEAtmDLXoip2qwwyg=";
  };

  # Final webroot: source tree with vendor/ dropped in and other/* moved to root.
  smfWebroot = pkgs.stdenv.mkDerivation {
    name = "smf-${smfVersion}-webroot";
    src = smfSource;
    buildPhase = ''
      cp -r ${smfVendor} vendor
      # SMF's repo ships Settings.php, install.php, upgrade.php, SQL schemas,
      # etc. under other/; the release tarball moves them to the webroot root.
      cp -r other/* .
      rm -rf other
    '';
    installPhase = ''
      mkdir -p $out
      cp -r . $out/
    '';
  };

  # Writable webroot. SMF's Settings.php, cache, attachments, avatars, Packages,
  webroot = "/var/lib/wokeforum";
  attachmentDir = "${clientPath}/media";
in
{
  options.site.modules.wokeforum = {
    server = {
      enable = lib.mkEnableOption "wokeforum NFS server role (runs on SAOTOME)";
    };

    client = {
      enable = lib.mkEnableOption "wokeforum NFS client role (runs on KAZOOIE)";
    };

    forum = {
      enable = lib.mkEnableOption "SMF forum on KAZOOIE (nginx + PHP-FPM + MariaDB)";

      domainName = lib.mkOption {
        type = lib.types.str;
        default = "forum.wokestory.org";
      };

      dbName = lib.mkOption {
        type = lib.types.str;
        default = "smf";
      };

      dbUser = lib.mkOption {
        type = lib.types.str;
        default = "smf";
      };

      dbPasswordFile = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/wokeforum/db.env";
        description = "Env file containing MYSQL_PASSWORD=<...> for the SMF DB user. Per [[secrets-via-env-files]] convention.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.server.enable || cfg.client.enable) {
      users.groups.wokestory.gid = wokestoryGid;
      users.users.wokestory = {
        uid = wokestoryUid;
        group = "wokestory";
        isSystemUser = true;
        home = "/var/lib/wokestory";
        createHome = false;
      };
    })

    (lib.mkIf cfg.server.enable {
      systemd.tmpfiles.rules = [
        "d ${serverPath} 0755 wokestory wokestory -"
      ];

      services.nfs.server = {
        enable = true;
        exports = ''
          ${serverPath} ${kazooieWgIp}/32(rw,sync,no_subtree_check,all_squash,anonuid=${toString wokestoryUid},anongid=${toString wokestoryGid})
        '';
      };

      networking.firewall.interfaces.wg0.allowedTCPPorts = [ 2049 ];
    })

    (lib.mkIf cfg.client.enable {
      fileSystems.${clientPath} = {
        device = "${saotomeWgIp}:${serverPath}";
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

    (lib.mkIf cfg.forum.enable {
      services.mysql = {
        enable = true;
        package = pkgs.mariadb;
        ensureDatabases = [ cfg.forum.dbName ];
        ensureUsers = [
          { name = cfg.forum.dbUser; }
        ];
      };

      services.phpfpm.pools.wokeforum = {
        user = "wokestory";
        group = "wokestory";
        settings = {
          "listen.owner" = "nginx";
          "listen.group" = "nginx";
          "pm" = "dynamic";
          "pm.max_children" = 20;
          "pm.start_servers" = 2;
          "pm.min_spare_servers" = 1;
          "pm.max_spare_servers" = 4;
        };
      };

      systemd.tmpfiles.rules = [
        "d ${webroot} 0755 wokestory wokestory -"
        "d ${webroot}/cache 0775 wokestory wokestory -"
        "d ${webroot}/attachments 0775 wokestory wokestory -"
        "d ${webroot}/avatars 0775 wokestory wokestory -"
        "d ${webroot}/Packages 0775 wokestory wokestory -"
        "d ${webroot}/Themes 0775 wokestory wokestory -"
        "d ${webroot}/Smileys 0775 wokestory wokestory -"
        "d ${attachmentDir} 0775 wokestory wokestory -"
      ];

      systemd.services.wokeforum-install = {
        description = "Install/upgrade SMF webroot";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network.target"
          "systemd-tmpfiles-setup.service"
        ];
        requires = [ "systemd-tmpfiles-setup.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "wokestory";
          Group = "wokestory";
        };
        path = [ pkgs.rsync ];
        script = ''
          # attachments is a symlink to the NFS mount; remove it so rsync doesn't write SMF core files through it.
          rm -rf ${webroot}/attachments

          # Settings.php existence is the first-install signal; once present, admin state must persist across rebuilds.
          if [ ! -f ${webroot}/Settings.php ]; then
            rsync -rc --no-perms ${smfWebroot}/ ${webroot}/
          else
            rsync -rc --no-perms \
              --exclude=Settings.php \
              --exclude=Settings_bak.php \
              --exclude=install.php \
              --exclude=upgrade.php \
              --exclude=db_last_error.php \
              --exclude='agreement*.txt' \
              --exclude=cache/ \
              --exclude=avatars/ \
              --exclude=attachments/ \
              --exclude=Packages/ \
              --exclude=Smileys/ \
              --exclude=Themes/ \
              ${smfWebroot}/ ${webroot}/
          fi

          mkdir -p ${webroot}/cache ${webroot}/avatars ${webroot}/Packages ${webroot}/Themes ${webroot}/Smileys
          chmod 0775 ${webroot}/cache ${webroot}/avatars ${webroot}/Packages ${webroot}/Themes ${webroot}/Smileys
          ln -s ${attachmentDir} ${webroot}/attachments
        '';
      };

      services.nginx = {
        enable = true;
        virtualHosts.${cfg.forum.domainName} = {
          forceSSL = true;
          enableACME = true;
          root = "${webroot}";
          extraConfig = ''
            index index.php;
            client_max_body_size 25M;
          '';
          locations = {
            "/install.php" = {
              return = 404;
            };
            "/upgrade.php" = {
              return = 404;
            };
            "/" = {
              tryFiles = "$uri $uri/ /index.php?$args";
            };
            "~ \.php$".extraConfig = ''
              fastcgi_split_path_info ^(.+\.php)(/.+)$;
              fastcgi_pass unix:${config.services.phpfpm.pools.wokeforum.socket};
              fastcgi_index index.php;
              include ${config.services.nginx.package}/conf/fastcgi.conf;
              fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
              fastcgi_param PATH_INFO $fastcgi_path_info;
            '';
          };
        };
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
    })
  ];
}
