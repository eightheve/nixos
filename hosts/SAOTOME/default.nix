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

  myUsers.sana = {
    enable = true;
    useHomeManager = true;
  };

  myUsers.cyanobacteria = {
    enable = true;
    useHomeManager = true;
  };

  fileSystems."/srv/data" = {
    device = "/dev/md0";
    fsType = "ext4";
  };

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

    forgejoRunner.enable = true;

    ssh = {
      enable = true;
      openFirewall = true;
    };

    slskd = {
      enable = true;
      settings = {
        useSlskdn = true;
        shareFolders = ["[RAID]/srv/data/music"];
        domainName = "soulseek.doppel.moe";
        enableNginx = true;
        localPort = "5030";
        environmentFilePath = "/var/lib/slskd/.env";
      };
    };

    navidrome = {
      enable = true;
      settings = {
        musicFolder = "/srv/data/music";
        environmentFilePath = "/var/lib/navidrome/.env";
        enableNginx = true;
        domainName = "navi.doppel.moe";
        localPort = "4533";
      };
    };

    wireguard = {
      enable = true;
      role = "client";
      ip = "10.100.0.2/24";
      peers = [
        {
          publicKey = "1I3PO1MgFdqffo816H34YalYgnCrwPo3ssBbsLTxzBg=";
          allowedIPs = ["10.100.0.0/24"];
          endpoint = "5.161.238.34:51820";
          persistentKeepalive = 25;
        }
      ];
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

  system.stateVersion = "25.11";
}
