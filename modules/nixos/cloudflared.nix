{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myModules.cloudflared;
in {
  options.myModules.cloudflared = {
    enable = lib.mkEnableOption "cloudflared tunnel";
  };

  config = lib.mkIf cfg.enable {
    environment.etc."cloudflared/config.yml".text = ''
      tunnel: a047f32f-c101-4f7c-9986-54c01a0eaaf2
      credentials-file: /etc/cloudflared/token.env

      ingress:
        - service: https://localhost:443
          originRequest:
            noTLSVerify: true
            httpHostHeader: doppel.moe
    '';

    systemd.services.cloudflared = {
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      serviceConfig = {
        ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate --config /etc/cloudflared/config.yml run";
        Restart = "always";
        EnvironmentFile = "/etc/cloudflared/token.env";
        DynamicUser = true;
      };
    };
  };
}
