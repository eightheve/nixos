{pkgs, ...}: {
  imports = [
    ./hardware.nix
  ];

  boot.loader = {
    efi.canTouchEfiVariables = false;
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 3;
  };

  users.mutableUsers = false;
  services.getty.autologinUser = "sana";

  hardware.bluetooth.enable = true;

  services.xserver = {
    enable = true;
    displayManager.startx.enable = true;
    videoDrivers = ["modesetting"];
  };

  environment.systemPackages = with pkgs; [
    libimobiledevice
  ];

  services.usbmuxd = {
    enable = true;
    package = pkgs.usbmuxd2;
  };

  myModules.networking = {
    enable = true;
    hostName = "BACTERIA";
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
    };
  };

  networking.firewall.enable = false;

  system.stateVersion = "25.11";
}
