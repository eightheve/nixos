{
  pkgs,
  pkgs-unstable,
  lib,
  ...
}: {
  imports = [
    ./hardware.nix
  ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  site.profiles.server.enable = true;

  myModules.networking = {
    enable = true;
    hostName = "sys";
  };
  networking.domain = "doppel.moe";

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "claude-code"
  ];

  environment.systemPackages = [
    pkgs.claude-code
    pkgs-unstable.mcp-nixos
  ];

  myModules.ssh.ports = [2222];

  myModules = {
    navidrome.nginx = {
      enable = true;
      upstream = "http://10.100.0.2:4533";
    };
    slskd.nginx = {
      enable = true;
      upstream = "http://10.100.0.2:5030";
    };
    sanaWebsite.enable = true;
    matrix.synapse.enable = true;
    wireguard.enable = true;
  };

  networking.firewall = {
    allowedTCPPorts = [443 80];
  };

  system.stateVersion = "25.05";
}
