{pkgs, ...}: {
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
    homeManager = {
      enable = true;
      enableLaptopSupport = true;
      windowManagers = ["dwm"];
      colorScheme = ../../colors/rin.nix;
      wallpaper = ../../assets/wallpapers/rin.jpg;
      enableDiscord = true;
    };
  };

  networking = {
    firewall.enable = true;
    modemmanager = {
      enable = true;
      fccUnlockScripts = [
        {
          id = "1199:9079";
          path = "${pkgs.modemmanager}/share/ModemManager/fcc-unlock.available.d/1199:9079";
        }
      ];
    };
  };

  system.stateVersion = "25.11";
}
