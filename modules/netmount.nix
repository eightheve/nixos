{
  config,
  lib,
  ...
}:
let
  topology = config.site.topology;
  me = config.site.modules.networking.hostName;

  entries = import ./netmount-entries.nix;

  wgIpOf =
    host:
    let
      h = topology.${host};
    in
    h.wireguard.interfaces.${builtins.head (builtins.attrNames h.wireguard.interfaces)}.ip;

  mkServer =
    _name: d:
    let
      here = d.server.host == me;
    in
    {
      systemd.tmpfiles.rules = lib.mkIf here [
        "d ${d.server.path} ${d.mode or "0777"} root root -"
      ];

      services.nfs.server = lib.mkIf here {
        enable = true;
        exports = ''
          ${d.server.path} ${wgIpOf d.client.host}/32(${
            if d.readonly or false then "ro" else "rw"
          },sync,no_subtree_check,no_root_squash)
        '';
      };

      networking.firewall.interfaces.wg0.allowedTCPPorts = lib.mkIf here [ 2049 ];
    };

  mkClient = _name: d: {
    fileSystems.${d.client.path} = lib.mkIf (d.client.host == me) {
      device = "${wgIpOf d.server.host}:${d.server.path}";
      fsType = "nfs";
      options = [
        "nfsvers=4"
        "noatime"
        "x-systemd.mkdir"
        "x-systemd.automount"
        "x-systemd.idle-timeout=5min"
        "x-systemd.device-timeout=10s"
        "x-systemd.mount-timeout=10s"
        "nofail"
      ];
    };
  };
in
{
  config = lib.mkMerge (lib.mapAttrsToList mkServer entries ++ lib.mapAttrsToList mkClient entries);
}
