{
  config,
  lib,
  ...
}:
let
  cfg = config.site.modules.searxng;
in
{
  options.site.modules.searxng = {
    enable = lib.mkEnableOption "SearXNG metasearch instance";

    bindAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = ''
        Address SearXNG binds to. Use the host's WireGuard IP to make it
        reachable for other hosts in the mesh (firewall then only allows the
        port on wg0).
      '';
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 8888;
    };

    environmentFilePath = lib.mkOption {
      type = lib.types.str;
      default = "/etc/searxng.env";
      description = ''
        Env file containing SEARXNG_SECRET_KEY=<random string>. Per the
        secrets-via-env-files convention.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.searx = {
      enable = true;
      environmentFile = cfg.environmentFilePath;
      settings = {
        server = {
          bind_address = cfg.bindAddress;
          port = cfg.port;
          secret_key = "$SEARXNG_SECRET_KEY";
          method = "GET";
        };
        search = {
          # Wayfinder needs the programmatic JSON API.
          formats = [
            "html"
            "json"
          ];
        };
      };
    };

    # Reachable only through the WireGuard mesh; never open to WAN.
    networking.firewall.interfaces.wg0.allowedTCPPorts = [ cfg.port ];
  };
}
