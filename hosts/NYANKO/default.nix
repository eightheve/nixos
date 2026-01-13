{...}: {
  imports = [
    ./hardware.nix
  ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/disk/by-id/wwn-0x55cd2e404b4d96b1";
  };

  myModules.networking = {
    enable = true;
    hostName = "NYANKO";
    staticAddresses = {
      enable = true;
      interfaces = {
        eno1 = "192.168.1.30";
      };
    };
  };

  myModules.forgejoRunner.enable = true;

  myModules.ssh = {
    enable = true;
    openFirewall = true;
  };

  myModules.remoteBuilds.builder.enable = true;

  system.stateVersion = "25.11";
}
