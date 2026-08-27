{
  pkgs,
  ...
}:
{
  imports = [
    ./hardware.nix
  ];

  nixpkgs.config.allowUnfree = true;

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

  services.vintagestory.enable = true;
  site.modules.mcWhitelist.enable = true;

  site.modules = {
    networking = {
      enable = true;
      hostName = "SAOTOME";
    };

    forgejoRunner.enable = true;

    slskd = {
      enable = true;
      settings = {
        useSlskdn = false;
        shareFolders = [ "[RAID]/srv/data/music" ];
        environmentFilePath = "/var/lib/slskd/.env";
        # KAZOOIE's nginx vhost proxies in over wg0 (10.100.0.2).
        webAddress = "10.100.0.2";
      };
    };

    navidrome = {
      enable = true;
      settings = {
        musicFolder = "/srv/data/music";
        environmentFilePath = "/var/lib/navidrome/.env";
      };
    };
    remoteBuilds.builder.enable = true;
    wokeforum.server.enable = true;
  };

  site.users.sana.enable = true;

  networking.firewall = {
    allowedUDPPorts = [ 42420 ];
    allowedTCPPorts = [
      80
      42420
      25565
    ];
  };

  users.users.sana.extraGroups = [ "libvirtd" ];
  systemd.tmpfiles.rules = [ "d /var/lib/wayfinder-vm 0755 wayfinder wayfinder -" ];

  system.stateVersion = "25.11";
}
