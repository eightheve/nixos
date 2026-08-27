# Cross-host NFS directory orchestration.
#
# Entries are pure data in ./netmount-entries.nix (one export per entry).
# Each host materializes only the roles that name it; the entry data must be
# import-time constant, because module config SHAPE cannot depend on option
# VALUES (host selection is done with mkIf guards instead).
#
# Access control is export-scope (single /32 peer over wg0), not file mode:
# NFS numeric uids pass through and the server directory is permissive
# (mode 0777) so the client service writes with its own uid, no uid pinning
# across machines. Anyone who can reach the export can rewrite it; the export
# is restricted to one trusted host in the mesh.
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
          },sync,no_subtree_check)
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
