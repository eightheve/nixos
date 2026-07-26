{...}: {
  imports = [
    ./hardware.nix
  ];

  boot.loader.grub = {
    enable = true;
    device = "PLACEHOLDER";
  };
  
  site.profiles.server.enable = true;
  site.modules = {
    networking.enable = true;
    networking.hostName = "HIME"
  };

  system.stateVersion = "26.05";
}
