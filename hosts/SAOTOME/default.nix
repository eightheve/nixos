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
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCyisOZgUpYQfX8lIxBpm6WYYwz15iWb+8KUMMV9C38qy6VLm7YBBR1uJt2IAhssPS1faAMrZ9jZiMm80+fLN60foNMNE9jpLP3BQvbesdMDPFDMPFTHC9SOwCG3N95ivMzYaBvBN5iyBGd4I20SpKvH+Lojtw2OxK9SUzcruzhm6oihsiIdJwyevlAZg9I5+gfHMVVbTQQluqv51iRttaKWxD2yLbhAqObyzsiF6L/FrxN3RuyuQfRm8C6+er73kv9ejrm+Q98UtkCnNB8/sg04sWN55lVGHRVnzia9ESjDJ6/VBEzxDoy9EyTHEzDQ6joOTVCFuKZZS14l36flXzPex/g24BP+5OBcbAQqODCiZIIagl779Z6DkVwhF9tK2oAtmjWZN1NX8OmAlBaAzYSVIAGMtwRV5uOXnzoOgaLJ9dGoEIp99wgIGx82SMW2K/aXm7blwGSxMPrZSpCDhqdGR/nGtWT2T6H+6C9hP5wMUIcvUmIRUAxbCtBe+QSZF8= artemis@artemis-Surface-Pro"
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
