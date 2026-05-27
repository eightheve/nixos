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

  site.profiles.desktop.enable = true;

  site.modules = {
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

  site.colorScheme = {
    enable = true;
    path = ../../colors/madoka.nix;
  };

  site.users.sana = {
    enable = true;
    wallpaper = ../../assets/wallpapers/madoka.jpg;
  };

  services = {
    xserver.videoDrivers = ["nvidia"];
    ollama.enable = true;
    ollama.package = pkgs-unstable.ollama-cuda;
    ollama.acceleration = "cuda";
  };

  programs.steam.enable = true;
  nixpkgs.config.allowUnfree = true;

  hardware = {
    nvidia = {
      open = true;
      nvidiaSettings = true;
    };
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
