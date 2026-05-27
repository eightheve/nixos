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
  };

  site.colorScheme = {
    enable = true;
    path = ../../colors/madoka.nix;
  };

  site.users.sana = {
    enable = true;
    wallpaper = ../../assets/wallpapers/madoka.jpg;
    additionalXinitrcCommands = [
      "xrandr --output HDMI-0 --mode 1920x1200 --rotate left --rate 60 --pos 0x0"
      "xrandr --output DP-2 --mode 1920x1080 --rate 144 --pos 1200x200"
    ];
  };

  services.xserver.videoDrivers = ["nvidia"];
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
      claude-code
    ]);

  system.stateVersion = "25.05";
}
