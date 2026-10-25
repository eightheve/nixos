{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.site.profiles.graphics;
  packages = import ../packages;
  c = config.site.colorScheme;

  filepicker = pkgs.writeShellScript "filepicker" ''
    export PATH=${lib.makeBinPath [ pkgs.nnn pkgs.coreutils ]}:$PATH
    export TERMCMD="${pkgs.kitty}/bin/kitty --class=filepicker}"
    exec ${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/nnn-wrapper.sh "$@"
  '';
in
{
  options.site.profiles.graphics = {
    enable = lib.mkEnableOption "graphics profile (GUI and display settings)";

    xinitCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra shell commands in the system xinitrc before exec dwm";
    };

    wallpapers = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "Wallpaper images (store paths) applied by feh --bg-fill on X start";
    };
  };

  config = lib.mkIf cfg.enable {
    hardware = {
      bluetooth.enable = true;
      graphics.enable32Bit = true;
    };

    services.xserver = {
      enable = true;
      displayManager.startx.enable = true;
    };

    environment.etc."x11/xinitrc".text = ''
      ${lib.concatStringsSep "\n" cfg.xinitCommands}
      dbus-update-activation-environment -- systemd DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP=dwm
      slstatus &
      feh --bg-fill ${lib.concatStringsSep " " cfg.wallpapers}
      exec dwm
    '';

    environment.systemPackages = with pkgs; [
      (packages.dwm {
        inherit pkgs lib;
        colorscheme = if c.enable then c.colors else null;
        isLaptop = config.site.profiles.laptop.enable;
        refreshRate = if config.site.profiles.laptop.enable then 120 else 144;
      })
      (packages.slstatus {
        inherit pkgs lib;
        isLaptop = config.site.profiles.laptop.enable;
      })
      xinit
      pavucontrol

      gsettings-desktop-schemas
    ];

    environment.sessionVariables = {
      XCURSOR_SIZE = "24";
      XCURSOR_THEME = "Bibata-Original-Classic";
    };

    nixpkgs.config.permittedInsecurePackages = [
      "librewolf-152.0.2-1"
      "librewolf-unwrapped-152.0.2-1"
    ];

    fonts = {
      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        noto-fonts-monochrome-emoji

        nerd-fonts.jetbrains-mono

        hachimarupop
        migmix
      ];

      fontconfig = {
        enable = true;

        antialias = true;
        hinting = {
          enable = true;
          style = "slight";
        };

        defaultFonts = {
          serif = [
            "Noto Serif"
            "Noto Serif CJK SC"
            "Noto Emoji"
          ];
          sansSerif = [
            "Noto Sans"
            "MigMix 2P"
            "Noto Sans CJK SC"
            "Noto Emoji"
          ];
          monospace = [
            "JetBrainsMono Nerd Font"
            "Noto Emoji"
          ];
          emoji = [ "Noto Emoji" ];
        };
      };
    };

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-termfilechooser ];
      config = {
        common = {
          default = [ "termfilechooser" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "termfilechooser" ];
        };
      };
    };

    environment.etc."xdg/xdg-desktop-portal-termfilechooser/config".text = ''
      [filechooser]
      cmd=${filepicker}
      default_dir=$HOME
    '';

    programs = {
      dconf.enable = true;
    };

    environment.sessionVariables.GTK_USE_PORTAL = "1";

    services.jack = {
      jackd.enable = true;
      alsa.enable = false;
      loopback.enable = true;
    };
    services.pipewire.enable = false;
    services.pulseaudio.enable = true;
    security.rtkit.enable = true;
  };
}
