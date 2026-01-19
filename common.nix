{
  pkgs,
  lib,
  ...
}: {
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

  security.sudo.wheelNeedsPassword = false;
  security.pam = {
    services.login.u2fAuth = true;
    yubico = {
      enable = true;
      mode = "challenge-response";
      id = ["24483552"];
    };
    u2f = {
      enable = true;
      settings = {
        cue = true;
        prompt = "touch yo thingy";
      };
    };
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  environment.shellInit = ''
    gpg-connect-agent /bye
    if [ -z "$SSH_AUTH_SOCK" ]; then
      export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
    fi
  '';

  services = {
    pcscd.enable = true;
    udisks2.enable = true;
    postfix = {
      enable = true;
      rootAlias = "sana";
      setSendmail = true;
    };
  };

  hardware.gpgSmartcards.enable = true;
  services.udev.packages = [pkgs.yubikey-personalization];

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

  environment.systemPackages = with pkgs; [
    yubioath-flutter
    yubikey-personalization
    yubico-piv-tool
    yubikey-manager

    tmux

    cryptsetup
    mailutils
    fastfetch
    btop
    wget
    curl
    git
    nnn
  ];
}
