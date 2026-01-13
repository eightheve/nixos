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

  myModules.wireguard = {
    enable = true;
    role = "server";
    ip = "10.100.0.1/24";
    server.natForwardPorts = true;
    peers = [
      {
        publicKey = "0hrwVOfaPGTs2bfHoGrHroHGqG2aJiiu8JO9o5/K0xg=";
        allowedIPs = ["10.100.0.2/32"];
      }
    ];
  };

  myModules.ssh = {
    enable = true;
    openFirewall = true;
    ports = [2222];
  };

  system.stateVersion = "25.05";
}
