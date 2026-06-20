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

  site.modules.networking = {
    enable = true;
    hostName = "KAZOOIE";
  };
  networking.domain = "doppel.moe";

  services.fathom-releases.enable = true;

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "claude-code"
  ];

  environment.systemPackages = [
    pkgs.claude-code
    pkgs-unstable.mcp-nixos
  ];

  site.modules.ssh.ports = [2222];

  site.modules = {
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
  };

  site.users.benjamin.enable = true;

  networking.firewall = {
    allowedTCPPorts = [443 80];
  };

  system.stateVersion = "25.05";
}
