{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./server.nix
    ./yubikey.nix
  ];

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

  documentation.man.generateCaches = lib.mkForce false;

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

  services.udisks2.enable = true;

  environment.systemPackages = with pkgs; [
    inputs.agenix.packages.x86_64-linux.default

    tmux
    cryptsetup
    mailutils
    fastfetch
    btop
    wget
    curl
    git
  ];
}
