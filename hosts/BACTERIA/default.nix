{...}: {
  imports = [
    ./hardware.nix
  ];

  boot.loader = {
    efi.canTouchEfiVariables = false;
    systemd-boot.enable = true;
    grub = {
      enable = false;
      device = "nodev";
      efiSupport = true;
      configurationLimit = 1;
      extraEntries = ''
        menuentry "NixOS Yubikey Handler" {
          insmod iso9660
          set isofile="/iso/nixos-yubikey.iso"
          loopback loop (hd0,gpt3)$isofile
          configfile (loop)/boot/grub/loopback.cfg
        }
      '';
    };
  };

  users.mutableUsers = false;
  services.getty.autologinUser = "sana";

  hardware.bluetooth.enable = true;

  services.xserver = {
    enable = true;
    displayManager.startx.enable = true;
    videoDrivers = ["modesetting"];
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
