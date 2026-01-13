{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myModules.slskd;
in {
  options.myModules.slskd = {
    enable = lib.mkEnableOption "web based soulseek client";

    settings = {
      useSlskdn = lib.mkEnableOption "use the slskdn fork instead of the primary package";

      soulseekListeningPort = lib.mkOption {
        type = lib.types.int;
        default = 50300;
      };

      shareFolders = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["[SHARE]/var/lib/slskd/shares"];
        description = "a label can be added in square brackets before the first / in the file path";
      };

      domainName = lib.mkOption {
        type = lib.types.str;
        default = "soulseek.doppel.moe";
      };

      enableNginx = lib.mkEnableOption "create nginx reverse proxy";

      localPort = lib.mkOption {
        type = lib.types.str;
        default = "5030";
      };

      environmentFilePath = lib.mkOption {
        type = lib.types.str;
        default = "/etc/slskd.env";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = lib.mkIf cfg.settings.useSlskdn [
      (import ../../overlays/slskdn.nix)
    ];

    users.users.slskd = {
      isSystemUser = true;
      group = "slskd";
      home = "/var/lib/slskd";
      createHome = true;
      homeMode = "774";
    };

    networking.firewall.allowedTCPPorts =
      if cfg.settings.enableNginx
      then [443 cfg.settings.soulseekListeningPort]
      else [cfg.settings.soulseekListeningPort];
    networking.firewall.allowedUDPPorts = [cfg.settings.soulseekListeningPort];

    services.nginx = lib.mkIf cfg.settings.enableNginx {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."${cfg.settings.domainName}" = {
        forceSSL = true;
        enableACME = lib.mkForce true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${cfg.settings.localPort}";
          proxyWebsockets = true;
        };
      };
    };

    security.acme = lib.mkIf cfg.settings.enableNginx {
      acceptTerms = true;
      defaults.email = "sana@doppel.moe";
    };

    systemd.services.slskd.serviceConfig = {
      UMask = "0003";
    };

    services.slskd = {
      enable = true;
      domain = "slskd.home.doppel.moe";
      openFirewall = true;
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
              members = ["ZippyZappy" "hi im casper" "kevinshieldsfunnymoments"];
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
          https = {
            disabled = false;
            port = 5031;
          };
        };
      };
    };
  };
}
