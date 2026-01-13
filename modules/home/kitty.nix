{
  config,
  lib,
  ...
}: let
  cfg = config.homeModules.kitty;
  c = config.colorScheme.termColors;
in {
  options.homeModules.kitty = {
    enable = lib.mkEnableOption "kitty terminal emulator";
  };

  config = lib.mkIf cfg.enable {
    programs.kitty = {
      enable = true;
      enableGitIntegration = true;
      settings =
        {
          mouse_hide_wait = "-1";
          window_padding_width = "0 8 8";
          cursor_shape = "block";
        }
        // lib.optionalAttrs config.colorScheme.enable {
          foreground = "#${c.color15}";
          background = "#${c.color00}";
          selection_foreground = "#${c.color00}";
          selection_background = "#${c.color15}";

          cursor_text_color = "background";

          color0 = "#${c.color00}";
          color1 = "#${c.color01}";
          color2 = "#${c.color02}";
          color3 = "#${c.color03}";
          color4 = "#${c.color04}";
          color5 = "#${c.color05}";
          color6 = "#${c.color06}";
          color7 = "#${c.color07}";
          color8 = "#${c.color08}";
          color9 = "#${c.color09}";
          color10 = "#${c.color10}";
          color11 = "#${c.color11}";
          color12 = "#${c.color12}";
          color13 = "#${c.color13}";
          color14 = "#${c.color14}";
          color15 = "#${c.color15}";
        };
    };
  };
}
