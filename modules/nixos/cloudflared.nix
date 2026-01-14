{
  config,
  lib,
  ...
}: let
  cfg = config.myModules.cloudflared;
in {
  options.myModules.cloudflared = {
    enable = lib.mkEnableOption "cloudflared tunnel";
  };

  config = lib.mkIf cfg.enable {
    services.cloudflared = {
      enable = true;
      tunnels = {
        "doppelsana" = {
          default = "http_status:404";
          ingress = {
            "doppel.moe" = "http://localhost:443";
            "*.doppel.moe" = "http://localhost:443";
          };
        };
      };
    };

    systemd.servies.cloudflared-tunnel-doppelsana.serviceConfig = {
      EnvironmentFile = "/etc/cloudflared/token.env";
    };
  };
}
