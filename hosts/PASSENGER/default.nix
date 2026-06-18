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
    };
    ssh = {
      enable = true;
      openFirewall = true;
    };
  };

  site.colorScheme = {
    enable = true;
    path = ../../colors/madoka.nix;
  };

  hjem.users.sana.files = {
    ".config/wallpaper-primary.jpg".source = ../../assets/wallpapers/madoka.jpg;
    ".config/wallpaper-secondary.jpg".source = ../../assets/wallpapers/madoka-solid.jpg;
  };

  site.users.sana = {
    enable = true;
    additionalXinitrcCommands = [
      "xrandr --output HDMI-0 --mode 1920x1200 --rotate left --rate 60 --pos 0x0"
      "xrandr --output DP-2 --mode 1920x1080 --rate 144 --pos 1200x200 --primary"
      "feh --bg-fill ~/.config/wallpaper-primary.jpg ~/.config/wallpaper-secondary.jpg &"
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
