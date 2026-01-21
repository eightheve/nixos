{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myUsers.sana;

  # Window manager specific configurations
  wmConfigs = {
    dwm = {
      colorScheme = ../../colors/rin.nix;
      wallpaper = ./assets/dwm-wallpaper.jpg;
      homeModules = {
        homeModules.windowManagers.dwm = {
          enable = true;
          makeXinitrc = true;
          babashkaStatus.enable = true;
          additionalInitCommands = [
            "feh --bg-fill /home/sana/.wallpaper.jpg"
          ];
        };
      };
    };

    hyprland = {
      colorScheme = ../../colors/madoka.nix;
      wallpaper = ./assets/hyprland-wallpaper.jpg;
      homeModules = {
        homeModules.windowManagers.hyprland.enable = true;
      };
    };
  };

  currentWmConfig = wmConfigs.${cfg.windowManager};
in {
  options.myUsers.sana = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable and manage the 'sana' user";
    };

    sshAccessPermitted = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    useHomeManager = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    windowManager = lib.mkOption {
      type = lib.types.enum ["hyprland" "niri" "dwm"];
      default = "dwm";
    };

    enableGraphics = lib.mkOption {
      type = lib.types.bool;
      default = config.hardware.graphics.enable;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      users.users.sana = {
        isNormalUser = true;
        createHome = true;
        description = "二葉さな";
        extraGroups = ["wheel" "networkmanager" "slskd" "input"];
        hashedPassword = "$y$j9T$aqLJPq7sjoh7G60UN.4dd1$Deb/3ODxhVw.Qd2uN.A0.QvOH8Oel9BF.ukD/aXnNd8";
        shell = pkgs.fish;

        openssh.authorizedKeys.keys = lib.mkIf cfg.sshAccessPermitted [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC1Mbo28yG2Oln+KLKYp84MI/4t8ImUBPtEN1sym9OVz0pRGtBAhjaF5DYVpLUm0D7+cyuA4G/yKmjN7AEtvxDsr7t9aZaGII16p1WX5KU+A9o8aldRJPZEqCKTNY/+mYpHOEj9p1L8PE7AymXMlPGhfL1xpwrApaO9gk9eIQkO2mbe9xE8HZKeJ/WPLDhoVI/yOn1Ulof2k2QvvrqHc78e28ieqk5lcmBn1apZe4IMVBfhK9Gtc4Wtmaga1Dya2YP7j5qc0I0vFXERI9Lr2wMHDHRy85nS5qzLFBMSc+OYVW1s0xn2u3XMeldyWcWWrCbOsY/W/V7Ojv0pwEAVfUTCjxEExjerGj9r78LZA9ICy+0j3+hTzn1D+b3LZkKPl1AXq4MI320YAo4M4nHtvpaaUsI/+6g0YBq+zpga8AoESyIyCtouY8nnTBraEcHBmoUK0ly1VBrBKMUB/sGe8xjOMmfxNwHSNEY6CqhGtf3UTXLq7NWuIHkKVmjIYtVbbsc0YWiovVT2hHsfLGVG5JYrTH/+vN7fDVq7VwMQnVQBXtzBmmntwmdSpeWU0w1x8mLWgMiGbLQxDJn2ee3p4C5ub0NPgCXsMbxEbsjC2eeRUMaKcyJS0LuSPkDlzk5Z9P05HkemaPfBNvnV1JwQ9kaT7Otvj7Ynr1OoXFZTgokPHw== cardno:24_483_552"
        ];
      };

      programs.fish.enable = true;
    })

    (lib.mkIf (cfg.enable && cfg.useHomeManager) {
      home-manager.users.sana = {
        home = {
          username = "sana";
          homeDirectory = "/home/sana";
          stateVersion = "25.11";
        };

        programs.git = {
          enable = true;
          settings = {
            gpg.program = "${pkgs.gnupg}/bin/gpg";
            user = {
              name = "doppelsana";
              email = "sana@doppel.moe";
            };
          };
          signing = {
            key = "64E2D72FF5BA8BEE12C16A3D57096169F7C8117C";
            signByDefault = true;
          };
        };

        homeModules = {
          nvim.enable = true;
          fastfetch.enable = true;
        };

        home.packages = with pkgs;
          [
            unar
            xar
            tree
            file
            xxd
            python3
            flavours
            ffmpeg-full
          ]
          ++ (lib.optionals (config.networking.hostName == "SATELLITE") [brightnessctl]);
      };
    })

    (lib.mkIf (cfg.enable && cfg.useHomeManager && cfg.enableGraphics) {
      nixpkgs.config.allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "discord"
        ];

      home-manager.users.sana = lib.mkMerge [
        {
          programs.mpv = {
            enable = true;
            defaultProfiles = ["gpu-hq"];
          };

          homeModules.beets = lib.mkIf (config.networking.hostName == "SAOTOME") {
            enable = true;
            settings.musicPath = "/srv/data/music/";
          };

          homeModules = {
            discord.enable = lib.mkIf (config.networking.hostName != "BACTERIA") true;
            kitty.enable = true;

            fish = {
              enable = true;
              settings = {
                useGitStatus = false;
                promptColors = lib.mkIf (cfg.windowManager == "hyprland") (let
                  colors = config.home-manager.users.sana.colorScheme.colors;
                in {
                  userName = colors.accent3."1";
                  filePath = colors.accent3."0";
                  remoteHost = colors.accent4."0";
                });
              };
            };

            supersonic = {
              enable = true;
              settings = {
                useCustomTheme = true;
                fontPaths = {
                  normal = "${pkgs.migmix}/share/fonts/truetype/migmix/migmix-1p-regular.ttf";
                  bold = "${pkgs.migmix}/share/fonts/truetype/migmix/migmix-1p-bold.ttf";
                };
              };
            };
          };

          home.packages = with pkgs; [
            librewolf
            audacity
            openutau
            krita
            gimp
            inkscape
            imv
            wine
            winetricks
            mupdf
          ];

          colorScheme = {
            enable = true;
            path = currentWmConfig.colorScheme;
          };

          home.file.".wallpaper.jpg".source = currentWmConfig.wallpaper;
          home.file.".wallpaper-color.jpg".source = ./assets/hyprland-color.jpg;
        }

        # Apply window manager specific config
        currentWmConfig.homeModules
      ];
    })
  ];
}
