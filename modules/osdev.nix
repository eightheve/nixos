# OS-dev VM workspace: system libvirtd + QEMU with UEFI (OVMF) firmware, and a
# RAID-backed working directory for VM images, ISOs, and scratch mountpoints.
#
# UEFI comes for free here: the NixOS libvirtd module reads the edk2 firmware
# descriptors shipped inside `pkgs.qemu` (share/qemu/firmware/*.json) and
# symlinks the OVMF code + nvram-template images into /run/libvirt/nix-ovmf.
# Domains created with `--boot uefi` therefore get real TianoCore firmware
# with a selectable boot menu at power-on (press ESC at the splash).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.site.modules.osdev;
in
{
  options.site.modules.osdev = {
    enable = lib.mkEnableOption "osdev VM workspace (libvirtd/qemu + OVMF + RAID working dir)";

    root = lib.mkOption {
      type = lib.types.str;
      default = "/srv/data/osdev";
      description = "Working directory containing images/, isos/ and mount/.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "sana";
      description = "Owner of the working directory tree (created via tmpfiles).";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd.enable = true;

    # Keep the working tree present across reboots (idempotent; the dirs are
    # expected to live on the RAID array at /srv/data).
    systemd.tmpfiles.rules = [
      "d ${cfg.root} 0755 ${cfg.user} users - -"
      "d ${cfg.root}/images 0755 ${cfg.user} users - -"
      "d ${cfg.root}/isos 0755 ${cfg.user} users - -"
      "d ${cfg.root}/mount 0755 ${cfg.user} users - -"
    ];

    # Expose partition devices (/dev/nbd0p1, ...) so qcow2 images can be
    # mounted on the host via qemu-nbd while their VM is shut down.
    boot.kernelModules = [ "nbd" ];
    boot.extraModprobeConfig = "options nbd max_part=16";

    environment.systemPackages = with pkgs; [
      virt-manager # virt-install / virt-clone / virt-xml (and the GUI if X-forwarded)
      virt-viewer # remote-viewer, for the spice console
    ];
  };
}
