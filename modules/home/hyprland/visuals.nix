{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.homeModules.windowManagers.hyprland.enable {
    programs.wofi.style = ''
      * {
        font-family: monospace;
        font-weight: bold;
        color = #${config.colorScheme.colors.shade5};
      }

      #input {
        background-color: #${config.colorScheme.colors.shade1}EE;
      }

      #outer-box {
        background-color: #${config.colorScheme.colors.shade0};
        border: 1px solid #${config.colorScheme.colors.shade2};

        padding: 8px;
      }
    '';

    wayland.windowManager.hyprland.settings = {
      # Refer to https://wiki.hypr.land/Configuring/Variables/
      # https://wiki.hypr.land/Configuring/Variables/#general
      general = lib.mkMerge [
        {
          gaps_in = 0;
          gaps_out = 0;
          border_size = 1;
          # Set to true enable resizing windows by clicking and dragging on borders and gaps
          resize_on_border = false;
          # Please see https://wiki.hypr.land/Configuring/Tearing/ before you turn this on
          allow_tearing = false;
          layout = "dwindle";
        }
        (lib.mkIf config.colorScheme.enable {
          # https://wiki.hypr.land/Configuring/Variables/#variable-types for info about colors
          "col.active_border" = "rgba(${config.colorScheme.colors.accent4."1"}ff)";
          "col.inactive_border" = "rgba(${config.colorScheme.colors.accent4."0"}ff)";
        })
      ];

      # https://wiki.hypr.land/Configuring/Variables/#decoration
      decoration = {
        rounding = 0;
        # Change transparency of focused and unfocused windows
        active_opacity = 1.0;
        inactive_opacity = 1.0;

        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };

        # https://wiki.hypr.land/Configuring/Variables/#blur
      };

      # https://wiki.hypr.land/Configuring/Variables/#animations
      animations = {
        enabled = true;
        # Default animations, see https://wiki.hypr.land/Configuring/Animations/ for more
        bezier = [
          "easeOutQuint,0.23,1,0.32,1"
          "easeInOutCubic,0.65,0.05,0.36,1"
          "linear,0,0,1,1"
          "almostLinear,0.5,0.5,0.75,1.0"
          "quick,0.15,0,0.1,1"
        ];

        animation = [
          "global, 1, 10, default"
          "border, 1, 5.39, easeOutQuint"
          "windows, 1, 4.79, easeOutQuint"
          "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
          "windowsOut, 1, 1.49, linear, popin 87%"
          "fadeIn, 1, 1.73, almostLinear"
          "fadeOut, 1, 1.46, almostLinear"
          "fade, 1, 3.03, quick"
          "layers, 1, 3.81, easeOutQuint"
          "layersIn, 1, 4, easeOutQuint, fade"
          "layersOut, 1, 1.5, linear, fade"
          "fadeLayersIn, 1, 1.79, almostLinear"
          "fadeLayersOut, 1, 1.39, almostLinear"
          "workspaces, 1, 1.94, almostLinear, fade"
          "workspacesIn, 1, 1.21, almostLinear, fade"
          "workspacesOut, 1, 1.94, almostLinear, fade"
        ];
      };
    };
  };
}
