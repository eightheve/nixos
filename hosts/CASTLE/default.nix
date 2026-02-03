{...}: {
  imports = [
    ./hardware.nix
  ];

  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    systemd-boot = {
      enable = true;
    };
  };

  hardware = {
    bluetooth.enable = true;
    sensor.iio.enable = true;
  };

  services.xserver = {
    enable = true;
    displayManager.startx.enable = true;
    videoDrivers = ["modesetting"];
  };

  myModules.networking = {
    enable = true;
    hostName = "CASTLE";
  };

  myUsers.sana = {
    enable = true;
    useHomeManager = true;
    windowManager = "dwm";
  };

  networking.firewall.enable = false;

  system.stateVersion = "25.11";
}
