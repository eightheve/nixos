# Pure data: cross-host NFS directory entries (imported as an attrset by
# modules/netmount.nix). Add entries here; every host imports this file and
# only materializes the roles that name it.
#
# Entry shape:
#   "<name>" = {
#     server = { host = "<topology host, default SAOTOME>"; path = "<dir>"; };
#     client = { host = "<topology host>"; path = "<mount point>"; };
#     readonly = false;   # optional: export ro when true
#     mode = "0777";      # optional: server dir mode (tmpfiles)
#   };
#
# Live-data migration for matrix-media-store from KAZOOIE local disk is
# manual; see proposals/netmount-module.md.
{
  "matrix-media-store" = {
    server = {
      host = "SAOTOME";
      path = "/srv/data/matrix-media";
    };
    client = {
      host = "KAZOOIE";
      path = "/var/lib/matrix-synapse/media_store";
    };
  };
}
