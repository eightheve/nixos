{...}: {
  imports = [
    ./hardware.nix
  ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  myModules.networking = {
    enable = true;
    hostName = "KAZOOIE";
  };

  myModules.ssh = {
    enable = true;
    openFirewall = true;
    ports = [2222];
  };

  myModules = {
    navidrome.nginx = {
      enable = true;
      upstream = "10.100.0.2:4533";
    };
    slskd.nginx = {
      enable = true;
      upstream = "10.100.0.2:5030";
    };
    sanaWebsite.enable = true;
  };

  networking.wireguard.interfaces.wg0 = {
    ips = ["10.100.0.1/24"];
    listenPort = 51820;
    privateKeyFile = "/etc/wireguard/privatekey";
    peers = [
      {
        publicKey = "0hrwVOfaPGTs2bfHoGrHroHGqG2aJiiu8JO9o5/K0xg=";
        allowedIPs = ["10.100.0.2/32"];
      }
    ];
  };

  networking.firewall = {
    allowedTCPPorts = [443 80];
    allowedUDPPorts = [51820];
    extraCommands = ''
      iptables -t nat -A PREROUTING -i enp1s0 -p tcp --dport 22 -j DNAT --to-destination 10.100.0.2:22
    '';
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
  };

  system.stateVersion = "25.05";
}
