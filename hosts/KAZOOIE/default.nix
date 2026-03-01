{...}: {
  imports = [
    ./hardware.nix
  ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  networking = {
    hostName = "KAZOOIE";
    firewall.allowedTCPPorts = [443 80 2086];
    firewall.allowedUDPPorts = [51820 51821 2086];
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

  networking.enableIPv6 = true;
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  networking.nat = {
    enable = true;
    externalInterface = "enp1s0";
    internalInterfaces = ["wg0"];
  };

  networking.firewall = {
    extraCommands = ''
      iptables -t nat -F PREROUTING
      iptables -t nat -A PREROUTING -i enp1s0 -p tcp ! --dport 2222 -j DNAT --to-destination 10.100.0.2
      iptables -t nat -A PREROUTING -i enp1s0 -p udp ! --dport 51820 -j DNAT --to-destination 10.100.0.2
      iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE
    '';
  };

  system.stateVersion = "25.05";
}
