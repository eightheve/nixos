{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "virtio_pci" "virtio_scsi" "usbhid" "sr_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "tmpfs";
      fsType = "tmpfs";
      options = [ "defaults" "mode=755" "size=4G" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/88CA-618D";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0022" ];
    };

  fileSystems."/home" =
    { device = "/dev/mapper/nixroot-home";
      fsType = "ext4";
    };

  fileSystems."/nix" =
    { device = "/dev/mapper/nixroot-nix";
      fsType = "btrfs";
      options = [ "noatime" "compress=zstd" ];
      neededForBoot = true;
    };

  fileSystems."/persist" =
    { device = "/dev/mapper/nixroot-persist";
      fsType = "ext4";
      neededForBoot = true;
    };

  swapDevices =
    [ { device = "/dev/mapper/nixroot-swap"; }
    ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
