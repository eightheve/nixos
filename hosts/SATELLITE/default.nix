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

  myModules.remoteBuilds.user = {
    enable = true;
    hosts = {
      HAMUKO-NIXREMOTE = {
        hostName = "192.168.1.20";
        proxyJump = "doppel.moe";
      };
      NYANKO-NIXREMOTE = {
        hostName = "192.168.1.30";
        proxyJump = "doppel.moe";
      };
      HIME-NIXREMOTE = {
        hostName = "192.168.1.40";
        proxyJump = "doppel.moe";
      };
    };
  };

  system.stateVersion = "25.11";
}
