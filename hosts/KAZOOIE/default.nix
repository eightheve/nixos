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
    firewall.allowedUDPPorts = [51820];
  };

  myUsers.sana = {
    enable = true;
    useHomeManager = false;
    sshAccessPermitted = true;
  };

  myModules.networking = {
    enable = true;
    hostName = "KAZOOIE";
  };

  myModules.wireguard = {
    enable = true;
    interfaces.wg0 = {
      role = "server";
      ip = "10.100.0.1/24";
      listenPort = 51820;
      privateKeyFile = "/etc/wireguard/privatekey";
      peers = [
        {
          publicKey = "0hrwVOfaPGTs2bfHoGrHroHGqG2aJiiu8JO9o5/K0xg=";
          allowedIPs = ["10.100.0.2/32"];
        }
      ];
    };
    server = {
      externalInterface = "enp1s0";
      interfaces = ["wg0"];
      natForwardPorts = true;
    };
  };

  myModules.ssh = {
    enable = true;
    openFirewall = true;
    ports = [2222];
  };

  system.stateVersion = "25.05";
}
