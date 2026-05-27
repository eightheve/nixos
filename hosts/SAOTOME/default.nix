{...}: {
  imports = [
    ./hardware.nix
  ];

  boot = {
    loader.grub = {
      enable = true;
      device = "/dev/disk/by-id/wwn-0x50000000000029e4";
    };
    swraid = {
      enable = true;
      mdadmConf = ''
        MAILADDR root
        DEVICE /dev/disk/by-id/wwn-0x5000c*
        ARRAY /dev/md0 level=5 num-devices=15 metadata=1.2 UUID=3486501f:98659bf6:1ed0661e:d875767d
      '';
    };
  };

  site.profiles.server.enable = true;

  fileSystems."/srv/data" = {
    device = "/dev/md0";
    fsType = "ext4";
  };

  networking.firewall.enable = true;

  myModules = {
    networking = {
      enable = true;
      hostName = "SAOTOME";
      staticAddresses = {
        enable = true;
        interfaces = {
          eno3 = "192.168.1.10";
        };
      };
    };

    wireguard.enable = true;

    forgejoRunner.enable = true;

    slskd = {
      enable = true;
      settings = {
        useSlskdn = true;
        shareFolders = ["[RAID]/srv/data/music"];
        environmentFilePath = "/var/lib/slskd/.env";
      };
    };

    navidrome = {
      enable = true;
      settings = {
        musicFolder = "/srv/data/music";
        environmentFilePath = "/var/lib/navidrome/.env";
      };
    };

    remoteBuilds.user = {
      enable = false;
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

  myUsers.sana.enable = true;

  system.stateVersion = "25.11";
}
