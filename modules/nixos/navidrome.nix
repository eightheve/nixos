{
  config,
  lib,
  ...
}: let
  cfg = config.myModules.navidrome;
in {
  options.myModules.navidrome = {
    enable = lib.mkEnableOption "navidrome music server";

    nginx = {
      enable = lib.mkEnableOption "nginx vhost";
      upstream = lib.mkOption {
        type = lib.types.str;
        default = "http://127.0.0.1:${cfg.settings.localPort}";
      };
      domainName = lib.mkOption {
        type = lib.types.str;
        default = "navi.doppel.moe";
      };
    };

    settings = {
      musicFolder = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/navidrome/music";
      };
      environmentFilePath = lib.mkOption {
        type = lib.types.str;
        default = "/etc/navidrome.env";
      };
      localPort = lib.mkOption {
        type = lib.types.int;
        default = 4533;
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      users.users.navidrome = {
        isSystemUser = true;
        group = "navidrome";
        home = "/var/lib/navidrome";
        createHome = true;
      };

      services.navidrome = {
        enable = true;
        user = "navidrome";
        group = "navidrome";
        openFirewall = true;
        environmentFile = cfg.settings.environmentFilePath;
        settings = {
          Port = cfg.settings.localPort;
          MusicFolder = cfg.settings.musicFolder;
          AlbumPlayCountMode = "normalized";
          Address = "0.0.0.0";
          "Tags.Genre.Split" = ["," ";" "/" "|"];
          EnableSharing = true;
        };
      };

      networking.firewall.allowedTCPPorts = [cfg.settings.localPort];
    })

    (lib.mkIf cfg.nginx.enable {
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        virtualHosts."${cfg.nginx.domainName}" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = cfg.nginx.upstream;
            proxyWebsockets = true;
          };
        };
      };

      networking.firewall.allowedTCPPorts = [80 443];
    })
  ];
}
