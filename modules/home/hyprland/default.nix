{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homeModules.windowManagers.hyprland;
in {
  options.homeModules.windowManagers.hyprland = {
    enable = lib.mkEnableOption "hyprland window manager";
  };

  imports = [
    ./binds.nix
    ./visuals.nix
    ./waybar.nix
  ];

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      slurp
      grim
      wl-clipboard
    ];

    homeModules.xdg.enable = true;

    programs.wofi.enable = true;
    services.mako = {
      enable = true;
      settings = lib.mkMerge [
        {
          on-button-left = "invoke-default-action";
          on-button-right = "dismiss";

          output = "HDMI-A-1";

          border-radius = 10;
          padding = "8";
          icon-border-radius = 8;
          default-timeout = 10000;
          outer-margin = 12;
        }
        (lib.mkIf config.colorScheme.enable {
          background-color = "#${config.colorScheme.colors.shade0}";
          text-color = "#${config.colorScheme.colors.shade5}";
          border-color = "#${config.colorScheme.colors.shade1}";
        })
      ];
    };

    home.pointerCursor = {
      gtk.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Original-Classic";
      size = 24;
    };

    home.file.".config/hypr/hyprpaper.conf".text = ''
      preload=~/.wallpaper.jpg
      preload=~/.wallpaper-color.jpg

      wallpaper=DP-2,~/.wallpaper.jpg
      wallpaper=HDMI-A-1,~/.wallpaper-color.jpg
    '';

    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        monitor = [
          "DP-1, disable"
          "HDMI-A-1, 1920x1200, 0x0, 1, transform, 1"
          "DP-2, 1920x1200, 1200x80, 1"
        ];

        workspace = [
          "1, monitor:DP-2"
          "2, monitor:DP-2"
          "3, monitor:DP-2"
          "4, monitor:DP-2"
          "5, monitor:DP-2"
          "6, monitor:DP-2"
          "7, monitor:DP-2"
          "8, monitor:DP-2"
          "9, monitor:DP-2"
          "10, monitor:HDMI-A-1"
        ];

        "$terminal" = "kitty";
        "$menu" = "wofi --show drun";

        exec-once = [
          "hyprpaper &"
          "waybar &"
          "mako &"
          "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1 &"
        ];

        env = [
          "XCURSOR_SIZE,24"
          "HYPRCURSOR_SIZE,24"
          "WLR_NO_HARDWARE_CURSORS,1"
        ];
        dwindle = {
          pseudotile = true; # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
          preserve_split = true; # You probably want this
        };

        master = {
          new_status = "master";
        };

        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
        };

        input = {
          kb_layout = "us,us(colemak)";
          kb_variant = "";
          kb_model = "";
          kb_options = "grp:win_space_toggle,compose:ralt";
          kb_rules = "";
          follow_mouse = 1;
          sensitivity = 0;
        };

        cursor = {
          sync_gsettings_theme = true;
          hide_on_touch = false;
          hide_on_key_press = false;
          inactive_timeout = 30;
          no_hardware_cursors = 1;
        };
      };
    };
  };
}
