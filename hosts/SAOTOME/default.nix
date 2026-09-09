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
  users.users.vintagestory.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIjGAvm8Y1Z0hbe2k0+uC/6bsvv5D0t3NUeylpT4CbavipBVTmhXis7vHE4++OpAKh5/S1WXOqsiOt47newh3ihaKxAmUL9lwWWEnWG9OWLfUou4dT20oAwxQfMqKI/GIiEvnqITS+A9s7Y4RkujUc/nH26LWz3y+HhL00aRrxoiharD7s1FEABt8ZFfytMcJs3BHqaxX7Et0SCI/swY0hfRCsN5fANnxS3/JLVRXzWF/rVwNClWtR4Z4nT+YdvbDVOT38/XPBqLvAcuRleOCmBAGKXRLfGMdp5/nILqa2alBBK2iHu7ICy0EqCt2J/GF07yqjAobH0b5RScuj9RQAI6zD4Z2/6N38rZ13ERU8FGym/F/Sh/dv7Q6/hVe0SkOZLnHzZr19ichEaJ8EtQDln823tRYOCrt6QY+n74sZ2ESdb9h5fqIP+RiF0Eo6jx7+5UW0ECAiuD1jgVjnzq4mVvW+O71hhiei+7vfz5Csfwusp+L92eTNLE+0a6ELFLc= artemis@artemis-Surface-Pro"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl0efGKxYqYOtO7jjo15OelNVthIkB/TZDCJIEZqOPi3g7ixgk3bQpPokKSBgeCAtcCvPIjrV/7QdywYOitjpG2VO3J5CzJ1nQ3luPrD52fip5YAEVlddYB1X2K2fwP6Fag4VzCPV5Jjl7ZJa1CkiwZcod1ElVaATPuDmmWKMf01Z6iEMHZ7+t3PwhHGb4A27E3MKWt+1guhbQtCKHFxW7AAbRryonbDLwVpfWCQidfBFZT0ccRiS4iWdkpCP+EHmAwHSaftUOnWX1wJQv+dJ/nqbAo3iwcjvkKii4RocPUjtO0z34793yC1w5Z5EfCv2xgcFWny+W8cq75qL/IkUT rsa-key-20260904"
  ];
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
        # KAZOOIE's nginx vhost proxies in over wg0 (10.100.0.2).
        address = "10.100.0.2";
      };
    };
    remoteBuilds.builder.enable = true;
    wokeforum.server.enable = true;
    wikipediaMirror = {
      server.enable = true;
      # Reachable over wg0 only; Wayfinder uses this from KAZOOIE.
      serve = {
        enable = true;
        bindAddress = "10.100.0.2";
      };
    };
    searxng = {
      enable = true;
      # Reachable over wg0 only; Wayfinder will use this from KAZOOIE.
      bindAddress = "10.100.0.2";
    };
    osdev.enable = true;
  };

  site.users.sana.enable = true;

  networking.firewall = {
    # Vintage Story is UDP-only on 42420.
    allowedUDPPorts = [ 42420 ];
    allowedTCPPorts = [
      80
      25565
    ];
  };

  users.users.sana.extraGroups = [ "libvirtd" ];

  system.stateVersion = "25.11";
}
