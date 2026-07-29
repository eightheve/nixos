{
  pkgs,
  pkgs-unstable,
  lib,
  ...
}: {
  imports = [
    ./hardware.nix
  ];

  services.wayfinder.enable = true;

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
  
  networking.nat = {
    enable = true;
    externalInterface = "enp1s0";
    internalInterfaces = [ "wg0" ];
    forwardPorts = [
      { sourcePort = 42420; destination = "10.100.0.2:42420"; proto = "udp"; }
      { sourcePort = 42420; destination = "10.100.0.2:42420"; proto = "tcp"; }
    ];
    extraCommands = ''
      iptables -t nat -A POSTROUTING -o wg0 -d 10.100.0.2 -p tcp --dport 42420 -j MASQUERADE
      iptables -t nat -A POSTROUTING -o wg0 -d 10.100.0.2 -p udp --dport 42420 -j MASQUERADE
    '';
  };

  services.fathom-releases.enable = true;

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
    maddy.enable = true;
    wokeforum.client.enable = true;
    wokeforum.forum.enable = true;
  };

  site.users.benjamin.enable = true;

  networking.firewall = {
    allowedTCPPorts = [443 80 22 45000 42420];
    allowedUDPPorts = [42420];
  };

  system.stateVersion = "25.05";
}
