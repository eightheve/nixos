{
  pkgs,
  lib,
  ...
}: {
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

  environment.systemPackages = [
    pkgs.libimobiledevice
    pkgs.sshuttle
    pkgs.unixtools.netstat
  ];

  services = {
    xserver = {
      enable = true;
      displayManager.startx.enable = true;
      videoDrivers = ["modesetting"];
    };
    usbmuxd = {
      enable = true;
      package = pkgs.usbmuxd2;
    };
  };

  myModules.networking = {
    enable = true;
    hostName = "CASTLE";
  };

  myUsers.sana = {
    enable = true;
    useHomeManager = true;
    windowManager = "dwmCastle";
  };

  networking.firewall.enable = false;
  networking.enableB43Firmware = true;

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "b43-firmware"
    ];

  system.stateVersion = "25.11";
}
