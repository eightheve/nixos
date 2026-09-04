{
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:
{
  imports = [
    ./hardware.nix
  ];

  services.wayfinder.enable = true;

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  site.profiles.server.enable = true;

  networking.domain = "doppel.moe";

  networking.nat =
    let
      ports = [
        {
          sourcePort = 42420;
          destination = "10.100.0.2:42420";
          proto = "udp";
        }
        {
          sourcePort = 42420;
          destination = "10.100.0.2:42420";
          proto = "tcp";
        }
        {
          sourcePort = 25565;
          destination = "10.100.0.2:25565";
          proto = "tcp";
        }
      ];
    in
    {
      enable = true;
      externalInterface = "enp1s0";
      internalInterfaces = [ "wg0" ];
      forwardPorts = ports;
      extraCommands = lib.concatMapStringsSep "\n" (
        p:
        "iptables -t nat -A POSTROUTING -o wg0 -d ${p.destination} -p ${p.proto} --dport ${toString p.sourcePort} -j MASQUERADE"
      ) ports;
    };

  services.fathom-releases.enable = true;

  services.journald.extraConfig = ''
    SystemMaxUse=500M
  '';

  systemd.tmpfiles.rules = [
    "d /srv/kazooie 0755 sana users - -"
    "d /srv/kazooie/www 0755 sana users - -"
  ];

  services.nginx = {
    enable = true;
    virtualHosts."kazooie.doppel.moe" = {
      forceSSL = true;
      enableACME = true;
      root = "/srv/kazooie/www";
      locations."/" = {
        tryFiles = "$uri $uri/ =404";
        extraConfig = ''
          autoindex on;
        '';
      };
    };
  };

  site.modules = {
    networking = {
      enable = true;
      hostName = "KAZOOIE";
    };
    ssh = {
      enable = true;
      openFirewall = true;
      ports = [ 2222 ];
    };
    navidrome.nginx = {
      enable = true;
      upstream = "http://10.100.0.2:4533";
    };
    slskd.nginx = {
      enable = true;
      upstream = "http://10.100.0.2:5030";
    };
    synthProxy.enable = true;
    remoteBuilds.user = {
      enable = true;
      hosts = {
        PASSENGER.hostName = "10.100.1.1";
        SAOTOME.hostName = "10.100.0.2";
      };
    };
    mcWhitelist.nginx.enable = true;
    sanaWebsite.enable = true;
    matrix.synapse.enable = true;
    maddy.enable = true;
    wokeforum.client.enable = true;
    wokeforum.forum.enable = true;
    wikipediaMirror.client.enable = true;
  };

  site.users.benjamin.enable = true;

  networking.firewall = {
    allowedTCPPorts = [
      443
      80
      22
      45000
      42420
      25565
    ];
    allowedUDPPorts = [ 42420 ];
  };

  system.stateVersion = "25.05";
}
