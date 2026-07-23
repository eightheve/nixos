{
  config,
  lib,
  ...
}: let
  cfg = config.site.modules.wokeforum;
  topology = config.site.topology;

  # Fixed UID/GID so file ownership is consistent across SAOTOME and KAZOOIE.
  # NFS all_squash on the server maps all client writes to this UID/GID,
  # so the forum process (running as this user on KAZOOIE) sees files it owns.
  wokestoryUid = 4242;
  wokestoryGid = 4242;

  serverPath = "/srv/data/wokestory";
  clientPath = "/srv/wokestory";

  saotomeWgIp = topology.SAOTOME.wireguard.interfaces.wg0.ip;
  kazooieWgIp = topology.KAZOOIE.wireguard.interfaces.wg0.ip;
in {
  options.site.modules.wokeforum = {
    server = {
      enable = lib.mkEnableOption "wokeforum NFS server role (runs on SAOTOME)";
    };

    client = {
      enable = lib.mkEnableOption "wokeforum NFS client role (runs on KAZOOIE)";
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

      # NFSv4 only needs 2049/tcp. Restrict to wg0 so the server isn't reachable from the public internet.
      networking.firewall.interfaces.wg0.allowedTCPPorts = [2049];
    })

    (lib.mkIf cfg.client.enable {
      fileSystems.${clientPath} = {
        device = "${saotomeWgIp}:${serverPath}";
        fsType = "nfs";
        options = [
          "nfsvers=4"
          "noatime"
          # Automount: only mount on first access, so KAZOOIE still boots if SAOTOME is down.
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
