{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.site.profiles.graphics;
in
{
  options.site.profiles.graphics = {
    enable = lib.mkEnableOption "graphics profile (GUI and display settings)";
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

    environment.systemPackages = with pkgs; [
      xorg.xinit
      pavucontrol
    ];

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
      extraPortals = with pkgs; [
        xdg-desktop-portal
        xdg-desktop-portal-gtk
      ];
      config = {
        common = {
          default = [
            "gtk"
          ];
        };
      };
    };

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
