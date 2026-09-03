{
  config,
  lib,
  site,
  ...
}:
let
  cfg = config.site.modules.navidrome;
in
{
  options.site.modules.navidrome = {
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
      address = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = ''
          Address navidrome binds to. Use the host's WireGuard IP when the
          nginx vhost lives on another host in the mesh (firewall then only
          allows the port on wg0).
        '';
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
        # Firewall is declared below (wg0-scoped); do not let the nixpkgs
        # module open the port globally.
        openFirewall = false;
        environmentFile = cfg.settings.environmentFilePath;
        settings = {
          Port = cfg.settings.localPort;
          MusicFolder = cfg.settings.musicFolder;
          AlbumPlayCountMode = "normalized";
          Address = cfg.settings.address;
          "Tags.Genre.Split" = [
            ","
            ";"
            "/"
            "|"
          ];
          EnableSharing = true;
        };
      };

      systemd.services.navidrome.serviceConfig.BindReadOnlyPaths = lib.mkAfter [ "/srv/data/audiobooks" ];

      # Only reachable through the WireGuard mesh (nginx proxies in from
      # another host); never open to WAN.
      networking.firewall.interfaces.wg0.allowedTCPPorts = [ cfg.settings.localPort ];
    })

    (lib.mkIf cfg.nginx.enable (
      site.lib.mkProxyVhost {
        domain = cfg.nginx.domainName;
        upstream = cfg.nginx.upstream;
        proxyWebsockets = true;
      }
    ))
  ];
}
