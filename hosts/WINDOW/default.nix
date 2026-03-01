{...}: {
  imports = [
    ./hardware.nix
  ];

  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    systemd-boot.enable = true;
  };

  myModules.networking = {
    enable = true;
    hostName = "WINDOW";
  };

  myUsers.sana = {
    enable = true;
    homeManager.enable = true;
  };

  system.stateVersion = "25.11";
}
