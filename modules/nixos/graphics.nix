{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.hardware.graphics.enable {
    environment.systemPackages = with pkgs; [
      xorg.xinit
      pavucontrol
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
          serif = ["Noto Serif" "Noto Serif CJK SC" "Noto Emoji"];
          sansSerif = ["Noto Sans" "MigMix 2P" "Noto Sans CJK SC" "Noto Emoji"];
          monospace = ["JetBrainsMono Nerd Font" "Noto Emoji"];
          emoji = ["Noto Emoji"];
        };
      };
    };

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      config = {
        common = {
          default = [
            "gtk"
          ];
        };
      };
    };

    services = {
      pulseaudio.enable = false;
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };
    };
    security.rtkit.enable = true;

    hardware.graphics.enable32Bit = true;
  };
}
