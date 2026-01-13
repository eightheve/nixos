{...}: {
  imports = [
    ../../users/sana

    ./hardware.nix
  ];

  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
  };

  boot.initrd.kernelModules = ["ideapad_laptop"];
  hardware = {
    bluetooth.enable = true;
    sensor.iio.enable = true;
    trackpoint = {
      enable = true;
    };
  };

  services.xserver = {
    enable = true;
    displayManager.startx.enable = true;
    videoDrivers = ["modesetting"];
  };

  myModules.networking = {
    enable = true;
    hostName = "SATELLITE";
  };

  myModules.ssh = {
    enable = true;
    openFirewall = true;
  };

  myUsers.sana = {
    enable = true;
    useHomeManager = true;
    sshAccessPermitted = true;
    windowManager = "dwm";
  };

  myModules.wireguard = {
    enable = true;
    interfaces.wg0 = {
      role = "client";
      ip = "10.100.1.2/24";
      privateKeyFile = "/etc/wireguard/privatekey";
      peers = [
        {
          publicKey = "1lD/5+I/v9LRxOjRhxI/b8HSpT8gnsJNB5mq/YfbaFE=";
          allowedIPs = ["0.0.0.0/0"]; # route all traffic through SAOTOME
          endpoint = "5.161.238.34:51821"; # KAZOOIE's IP, forwarded to SAOTOME
          persistentKeepalive = 25;
        }
      ];
    };
  };

  system.stateVersion = "25.11";
}
