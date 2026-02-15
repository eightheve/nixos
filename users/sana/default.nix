{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myUsers.sana;

  windowManagerConfigs = {
    dwm = {
      homeModules = {
        windowManagers.dwm = {
          enable = true;
          additionalInitCommands = [
            "systemctl --user start slstatus &"
            "feh --bg-fill /home/sana/.wallpaper.jpg &"
          ];
          autoRotate.enable = cfg.homeManager.enableLaptopSupport;
        };
        suckless.slstatus = {
          enable = true;
        };
      };
    };

    hyprland = {
      homeModules.windowManagers.hyprland.enable = true;
    };
  };

  availableWindowManagers = builtins.attrNames windowManagerConfigs;
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

    enableGraphics = lib.mkOption {
      type = lib.types.bool;
      default = cfg.homeManager.windowManagers != [];
    };

    homeManager = {
      enable = lib.mkEnableOption "home manager for sana";

      enableLaptopSupport = lib.mkEnableOption "laptop features (brightnessctl, autorotate for x11, etc)";

      windowManagers = lib.mkOption {
        type = lib.types.listOf (lib.types.enum availableWindowManagers);
        default = [];
      };

      colorScheme = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
      };

      wallpaper = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
      };

      enableDiscord = lib.mkEnableOption "equibop discord client";
      enableVintageStory = lib.mkEnableOption "vintagestory game";
      beets = {
        enable = lib.mkEnableOption "beets music library manager";
        libraryPath = lib.mkOption {
          type = lib.types.str;
          default = "/srv/data/music/";
        };
      };
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

    (lib.mkIf (cfg.enable && cfg.homeManager.enable) {
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
          nvim = {
            enable = true;
            enableProseSupport = true;
          };
          fastfetch.enable = true;

          beets = {
            enable = cfg.homeManager.beets.enable;
            settings.musicPath = cfg.homeManager.beets.libraryPath;
          };
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
          ++ (lib.optionals (cfg.homeManager.enableLaptopSupport) [brightnessctl]);
      };
    })

    (lib.mkIf (cfg.enable && cfg.homeManager.enable && cfg.enableGraphics) {
      myModules.vintagestoryOverlay.enable = cfg.homeManager.enableVintageStory;
      nixpkgs.config.allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "discord"
        ];

      home-manager.users.sana = lib.mkMerge ([
          {
            programs.mpv = {
              enable = true;
              defaultProfiles = ["gpu-hq"];
            };

            homeModules = {
              discord.enable = cfg.homeManager.enableDiscord;
              kitty.enable = true;

              games.vintagestory = {
                enable = cfg.homeManager.enableVintageStory;
                versions = [
                  "latest"
                  "v1-20-12"
                ];
              };

              fish = {
                enable = true;
                settings.useGitStatus = false;
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
              path = cfg.homeManager.colorScheme;
            };

            home.file.".wallpaper.jpg".source = cfg.homeManager.wallpaper;
            home.file.".wallpaper-color.jpg".source = ./assets/hyprland-color.jpg;
          }
        ]
        ++ (map (wm: windowManagerConfigs.${wm}) cfg.homeManager.windowManagers));
    })
  ];
}
