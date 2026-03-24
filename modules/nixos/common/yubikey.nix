{
  pkgs,
  lib,
  ...
}: {
  security.pam = {
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

  services.pcscd.enable = true;

  hardware.gpgSmartcards.enable = true;
  services.udev.packages = [pkgs.yubikey-personalization];

  environment.systemPackages = with pkgs; [
    yubioath-flutter
    yubikey-personalization
    yubico-piv-tool
    yubikey-manager
  ];
}
