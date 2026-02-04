{...}: {
  imports = [
    ./hardware.nix
  ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/disk/by-id/wwn-0x55cd2e404b4d7cc5";
  };

  boot.swraid = {
    enable = true;
    mdadmConf = ''
      MAILADDR root
      DEVICE /dev/disk/by-id/scsi-35000c*
      ARRAY /dev/md0 level=5 num-devices=12 UUID=86d3d56d:a781c339:a7c90d5d:b252403a;
    '';
  };

  fileSystems."/srv/data" = {
    device = "/dev/md0";
    fsType = "ext4";
  };

  myModules.networking = {
    enable = true;
    hostName = "HIME";
    staticAddresses = {
      enable = true;
      interfaces = {
        eno1 = "192.168.1.40";
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
