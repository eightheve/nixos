{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homeModules.windowManagers.dwm;

  terminal =
    if config.homeModules.kitty.enable
    then ["${pkgs.kitty}/bin/kitty"]
    else ["${pkgs.st}/bin/st"];

  colorCfg = config.colorScheme;
  colors =
    if colorCfg.enable
    then {
      gray1 = "#${colorCfg.colors.shade0}";
      gray2 = "#${colorCfg.colors.shade2}";
      gray3 = "#${colorCfg.colors.shade3}";
      gray4 = "#${colorCfg.colors.shade5}";
      accent1 = "#${colorCfg.colors.accent4."0"}";
      accent2 = "#${colorCfg.colors.accent4."1"}";
    }
    else {
      gray1 = "#000000";
      gray2 = "#181818";
      gray3 = "#e1e1e1";
      gray4 = "#ffffff";
      accent1 = "#222244";
      accent2 = "#444477";
    };

  screenshotAll = pkgs.writeShellScript "screenshot-all" ''
    mkdir -p "${config.home.homeDirectory}/Resources/.screenshots"
    ${pkgs.scrot}/bin/scrot "/home/sana/Resources/.screenshots/%m-%d-%Y-%H%M%S.png" -e '${pkgs.xclip}/bin/xclip -selection clipboard -t image/png -i $f'
  '';

  screenshotSelection = pkgs.writeShellScript "screenshot-selection" ''
    mkdir -p "${config.home.homeDirectory}/Resources/.screenshots"
    ${pkgs.scrot}/bin/scrot "/home/sana/Resources/.screenshots/%m-%d-%Y-%H%M%S.png" --select --line mode=edge -e '${pkgs.xclip}/bin/xclip -selection clipboard -t image/png -i $f'
  '';

  dwmConfig = import ./config.nix {inherit (pkgs) lib;};
in {
  options.homeModules.windowManagers.dwm = {
    enable = lib.mkEnableOption "dwm";

    makeXinitrc = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    additionalInitCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "A list of additional commands to write to ~/.xinitrc";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      (dwm.overrideAttrs (oldAttrs: {
        #patches = [
        #  ./patches/
        #];
        postPatch = ''
          cp ${pkgs.writeText "config.h" (dwmConfig.mkDwmConfig {
            borderpx = 1;
            fonts = ["monospace:size=10"];
            termcmd = terminal;
            modkey = "Mod4Mask";
            colors = {
              norm = {
                fg = colors.gray3;
                bg = colors.gray1;
                border = colors.gray2;
              };
              sel = {
                fg = colors.gray4;
                bg = colors.accent1;
                border = colors.accent2;
              };
            };
            extraCommands = ''
              static const char *up_vol[]   = { "${pkgs.pulseaudio}/bin/pactl", "set-sink-volume", "@DEFAULT_SINK@", "+10%",   NULL };
              static const char *down_vol[] = { "${pkgs.pulseaudio}/bin/pactl", "set-sink-volume", "@DEFAULT_SINK@", "-10%",   NULL };
              static const char *mute_vol[] = { "${pkgs.pulseaudio}/bin/pactl", "set-sink-mute",   "@DEFAULT_SINK@", "toggle", NULL };
              static const char *brighter[] = { "${pkgs.brightnessctl}/bin/brightnessctl", "set", "10%+", "-e", "-n", "10%", NULL };
              static const char *dimmer[]   = { "${pkgs.brightnessctl}/bin/brightnessctl", "set", "10%-", "-e", "-n", "10%", NULL };
              static const char *ss_all[]   = { "${screenshotAll}", NULL };
              static const char *ss_sel[]   = { "${screenshotSelection}", NULL };
            '';
            extraKeys = ''
              { 0, XF86XK_AudioMute,         spawn, {.v = mute_vol } },
              { 0, XF86XK_AudioLowerVolume,  spawn, {.v = down_vol } },
              { 0, XF86XK_AudioRaiseVolume,  spawn, {.v = up_vol } },
              { 0, XF86XK_MonBrightnessDown, spawn, {.v = dimmer } },
              { 0, XF86XK_MonBrightnessUp,   spawn, {.v = brighter } },
              { 0,           XK_Print,       spawn, {.v = ss_all } },
              { ShiftMask,   XK_Print,       spawn, {.v = ss_sel } },
            '';
          })} config.h
        '';
      }))
      dmenu
      st
      feh
      pulseaudio
    ];

    home.pointerCursor = {
      gtk.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Original-Classic";
      size = 24;
    };

    home.file.".xinitrc".text = lib.mkIf cfg.makeXinitrc ''
      ${lib.concatStringsSep "\n" cfg.additionalInitCommands}
      exec dwm
    '';
  };
}
