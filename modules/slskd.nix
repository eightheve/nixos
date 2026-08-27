{
  config,
  lib,
  pkgs,
  site,
  ...
}:
let
  cfg = config.site.modules.slskd;
in
{
  options.site.modules.slskd = {
    enable = lib.mkEnableOption "web based soulseek client";

    nginx = {
      enable = lib.mkEnableOption "nginx vhost";
      upstream = lib.mkOption {
        type = lib.types.str;
        default = "http://127.0.0.1:${cfg.settings.localPort}";
      };
      domainName = lib.mkOption {
        type = lib.types.str;
        default = "soulseek.doppel.moe";
      };
    };

    settings = {
      useSlskdn = lib.mkEnableOption "use the slskdn fork instead of the primary package";

      soulseekListeningPort = lib.mkOption {
        type = lib.types.int;
        default = 50300;
      };

      shareFolders = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "[SHARE]/var/lib/slskd/shares" ];
        description = "a label can be added in square brackets before the first / in the file path";
      };

      localPort = lib.mkOption {
        type = lib.types.int;
        default = 5030;
      };

      webAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = ''
          Address the slskd web UI binds to. Use the host's WireGuard IP when
          the nginx vhost lives on another host in the mesh (firewall then only
          allows the port on wg0).
        '';
      };

      environmentFilePath = lib.mkOption {
        type = lib.types.str;
        default = "/etc/slskd.env";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      nixpkgs.overlays = lib.mkIf cfg.settings.useSlskdn [
        (import ../../overlays/slskdn.nix)
      ];

      users.users.slskd = {
        isSystemUser = true;
        group = "slskd";
        home = "/var/lib/slskd";
        createHome = true;
        homeMode = "750";
      };

      networking.firewall.allowedTCPPorts = [
        cfg.settings.soulseekListeningPort
      ];
      networking.firewall.allowedUDPPorts = [ cfg.settings.soulseekListeningPort ];
      # Web UI only reachable through the WireGuard mesh (nginx proxies in from
      # another host); never open to WAN.
      networking.firewall.interfaces.wg0.allowedTCPPorts = [ cfg.settings.localPort ];

      systemd.services.slskd.serviceConfig = {
        UMask = "0027";
      };

      services.slskd = {
        enable = true;
        domain = "slskd.home.doppel.moe";
        # Firewall rules are declared explicitly above (TCP+UDP soulseek port,
        # wg0-scoped web UI); do not let the nixpkgs module add its own.
        openFirewall = false;
        environmentFile = cfg.settings.environmentFilePath;
        group = "slskd";
        user = "slskd";

        settings = {
          directories = {
            incomplete = "/var/lib/slskd/incomplete";
            downloads = "/var/lib/slskd/downloads";
          };
          shares = {
            directories = cfg.settings.shareFolders;
            cache = {
              storage_mode = "memory";
              workers = 12;
              retention = 1440;
            };
          };

          global = {
            upload = {
              slots = 10;
              speed_limit = 10000;
            };
            download = {
              slots = 500;
              speed_limit = 10000;
            };
          };
          groups = {
            default = {
              upload = {
                priority = 500;
                strategy = "roundrobin";
                slots = 10;
              };
            };
            leechers = {
              upload = {
                priority = 999;
                strategy = "roundrobin";
                slots = 1;
                speed_limit = 100;
              };
            };
            user_defined = {
              buddies = {
                upload = {
                  priority = 250;
                  queue_strategy = "firstinfirstout";
                  slots = 20;
                };
                members = [
                  "ZippyZappy"
                  "hi im casper"
                  "kevinshieldsfunnymoments"
                ];
              };
            };
          };

          soulseek = {
            distributed_network = {
              child_limit = 20;
            };
            description = ''
              puppy thing located in us-east
              metadata is managed by beets, please message me if i have bad metadata or missing tracks.
              you can also message me if you have music recommendations. i love emo and math rock
            '';
            picture = "/var/lib/slskd/profile-picture.jpg";
          };

          web = {
            address = cfg.settings.webAddress;
            https = {
              disabled = false;
              port = 5031;
            };
          };
          overlay.keyPath = "/var/lib/slskd/mesh-overlay.key";
          mesh = {
            enableOverlay = false;
            enableDht = false;
          };
        };
      };
    })

    (lib.mkIf cfg.nginx.enable (
      site.lib.mkProxyVhost {
        domain = cfg.nginx.domainName;
        upstream = cfg.nginx.upstream;
        enableACME = lib.mkForce true;
        proxyWebsockets = true;
      }
    ))
  ];
}
