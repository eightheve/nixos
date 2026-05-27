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

  hardware.trackpoint.enable = true;

  site.profiles.laptop.enable = true;

  myModules.networking = {
    enable = true;
    hostName = "SATELLITE";
  };

  site.colorScheme = {
    enable = true;
    path = ../../colors/rin.nix;
  };

  myUsers.sana = {
    enable = true;
    wallpaper = ../../assets/wallpapers/rin.jpg;
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
