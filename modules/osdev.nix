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

    systemd.tmpfiles.rules = [
      "d ${cfg.root} 0755 ${cfg.user} users - -"
      "d ${cfg.root}/images 0755 ${cfg.user} users - -"
      "d ${cfg.root}/isos 0755 ${cfg.user} users - -"
      "d ${cfg.root}/mount 0755 ${cfg.user} users - -"

      "L+ /var/lib/libvirt/qemu/networks/autostart/default.xml - - - - /var/lib/libvirt/qemu/networks/default.xml"
    ];

    networking.firewall.trustedInterfaces = [ "virbr0" ];
    boot.kernel.sysctl."net.ipv4.ip_forward" = true;
    boot.kernelModules = [ "nbd" ];
    boot.extraModprobeConfig = "options nbd max_part=16";

    environment.systemPackages = with pkgs; [
      virt-manager
    ];
  };
}
