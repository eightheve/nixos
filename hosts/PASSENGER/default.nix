{pkgs, ...}: {
  imports = [
    ./hardware.nix
  ];

  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      devices = ["nodev"];
      efiSupport = true;
      useOSProber = true;
    };
  };

  services.xserver = {
    enable = true;
    displayManager.startx.enable = true;
    videoDrivers = ["nvidia"];
  };

  myModules = {
    ssh = {
      enable = true;
      openFirewall = true;
    };

    networking = {
      enable = true;
      hostName = "PASSENGER";
      staticAddresses = {
        enable = true;
        interfaces = {
          enp12s0 = "192.168.1.5";
        };
      };
    };
  };

  myUsers.sana = {
    enable = true;
    useHomeManager = true;
    windowManager = "hyprland";
  };

  programs.steam.enable = true;
  nixpkgs.config.allowUnfree = true;

  hardware = {
    nvidia = {
      open = true;
      nvidiaSettings = true;
    };
    bluetooth.enable = true;
    opentabletdriver = {
      enable = true;
      daemon.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    vulkan-tools
    libGL
    pciutils
    gwe
    lm_sensors
    pulseaudio

    gamescope
    prismlauncher
    ckan
  ];

  system.stateVersion = "25.05";
}
