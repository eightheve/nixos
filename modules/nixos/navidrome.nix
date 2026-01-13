{
  config,
  lib,
  ...
}: let
  cfg = config.myModules.navidrome;
in {
  options.myModules.navidrome = {
    enable = lib.mkEnableOption "navidrome music server";

    settings = {
      musicFolder = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/navidrome/music";
      };

      environmentFilePath = lib.mkOption {
        type = lib.types.str;
        default = "/etc/navidrome.env";
      };

      enableNginx = lib.mkEnableOption "nginx proxy";

      domainName = lib.mkOption {
        type = lib.types.str;
        default = "navi.doppel.moe";
      };

      localPort = lib.mkOption {
        type = lib.types.str;
        default = "4533";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.navidrome = {
      isSystemUser = true;
      group = "navidrome";
      home = "/var/lib/navidrome";
      createHome = true;
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.settings.enableNginx [443];

    services.navidrome = {
      enable = true;
      user = "navidrome";
      group = "navidrome";
      openFirewall = false;
      environmentFile = cfg.settings.environmentFilePath;
      settings = {
        MusicFolder = cfg.settings.musicFolder;
        AlbumPlayCountMode = "normalized";
        "Tags.Genre.Split" = ["," ";" "/" "|"];
        EnableSharing = true;
      };
    };

    services.nginx = lib.mkIf cfg.settings.enableNginx {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."${cfg.settings.domainName}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${cfg.settings.localPort}";
          proxyWebsockets = true;
        };
      };
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = "sana@doppel.moe";
    };
  };
}
