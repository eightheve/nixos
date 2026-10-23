{
  pkgs,
  pkgs-unstable,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./hardware.nix
    inputs.impermanence.nixosModules.impermanence
  ];

  environment.persistence."/persist" = {
    enable = true;
    directories = [
      "/var/log"
      "/var/lib/nixos"
      "/etc/nixos"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  site.profiles.server.enable = true;

  networking.domain = "doppel.moe";

  services.getty.autologinUser = "sana";

  services.journald.extraConfig = ''
    SystemMaxUse=500M
  '';
 
  services.qemuGuest.enable = true;

  site.modules = {
    networking = {
      enable = true;
      hostName = "SILFA";
    };
    ssh = {
      enable = true;
      openFirewall = true;
      ports = [ 22 ];
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      443
      80
      22
      45000
    ];
    allowedUDPPorts = [ 42420 ];
  };

  system.stateVersion = "26.05";
}
