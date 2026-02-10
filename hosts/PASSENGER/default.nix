{
  pkgs,
  pkgs-unstable,
  ...
}: {
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

  services.ollama.enable = true;
  services.ollama.package = pkgs-unstable.ollama-cuda;
  services.ollama.acceleration = "cuda";

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

    remoteBuilds.user = {
      enable = true;
      hosts = {
        HAMUKO-NIXREMOTE = {
          hostName = "192.168.1.20";
        };
        NYANKO-NIXREMOTE = {
          hostName = "192.168.1.30";
        };
        HIME-NIXREMOTE = {
          hostName = "192.168.1.40";
        };
      };
    };
  };

  myUsers.sana = {
    enable = true;
    homeManager = {
      enable = true;
      windowManagers = ["hyprland"];
      colorScheme = ../../colors/madoka.nix;
      wallpaper = ../../assets/wallpapers/madoka.jpg;
      enableDiscord = true;
      enableVintageStory = true;
    };
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

  environment.systemPackages =
    (with pkgs; [
      vulkan-tools
      libGL
      pciutils
      gwe
      lm_sensors
      pulseaudio

      gamescope
      prismlauncher
      ckan
    ])
    ++ (with pkgs-unstable; [
      ollama-cuda
      claude-code
    ]);

  system.stateVersion = "25.05";
}
