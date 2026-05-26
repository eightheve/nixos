{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.site.profiles.common;
in {
  options.site.profiles.common = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable common system profile (base settings for all hosts)";
    };
  };

  config = lib.mkIf cfg.enable {
    nix = {
      settings = {
        experimental-features = "nix-command flakes";
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
    };

    security = {
      sudo.wheelNeedsPassword = false;

      pam = {
        services.login.u2fAuth = true;
        yubico = {
          enable = true;
          mode = "challenge-response";
          id = ["24483552"];
        };
        u2f = {
          enable = true;
        };
      };
    };

    hardware = {
      gpgSmartcards.enable = true;
    };

    services = {
      udisks2.enable = true;
      pcscd.enable = true;
      udev.packages = [pkgs.yubikey-personalization];
    };

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    environment = {
      shellInit = ''
        gpg-connect-agent /bye
        if [ -z "$SSH_AUTH_SOCK" ]; then
          export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
        fi
      '';

      systemPackages = with pkgs; [
        inputs.agenix.packages.x86_64-linux.default

        tmux
        cryptsetup
        mailutils
        fastfetch
        btop
        wget
        curl
        git

        yubioath-flutter
        yubikey-personalization
        yubico-piv-tool
        yubikey-manager
      ];
    };

    time.timeZone = lib.mkDefault "America/New_York";

    i18n = {
      defaultLocale = "en_US.UTF-8";
      supportedLocales = ["en_US.UTF-8/UTF-8" "ja_JP.UTF-8/UTF-8"];
      extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };
    };

    documentation.man.generateCaches = lib.mkForce false;
  };
}
