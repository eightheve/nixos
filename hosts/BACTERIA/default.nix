{...}: {
  imports = [
    ./hardware.nix
  ];

  boot.loader = {
    efi.canTouchEfiVariables = false;
    systemd-boot = {
      enable = true;
      configurationLimit = 1;
    };
  };

  users.mutableUsers = false;
  services.getty.autoLoginUser = "sana";

  hardware.bluetooth.enable = true;

  services.xserver = {
    enable = true;
    displayManager.startx.enable = true;
    videoDrivers = ["modesetting" "intel" "amd" "nvidia"];
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
    useHomeManager = true;
    sshAccessPermitted = true;
    windowManager = "dwm";
  };

  networking.firewall.enable = false;

  system.stateVersion = "25.11";
}
