{
  config,
  lib,
  ...
}: let
  cfg = config.site.modules.networking;
in {
  options.site.modules.networking = {
    enable = lib.mkEnableOption "networking";

    hostName = lib.mkOption {
      type = lib.types.str;
      default = "nixos";
    };

    staticAddresses = {
      enable = lib.mkEnableOption "use a static IP address";

      interfaces = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "Map of interface names to static IP addresses";
        example = {eno1 = "192.168.1.1";};
      };

      defaultGateway = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.1";
        description = "Default gateway address for static IP configuration";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      hostName = cfg.hostName;

      networkmanager.enable = !cfg.staticAddresses.enable;

      interfaces = lib.mkIf cfg.staticAddresses.enable (
        lib.mapAttrs (interface: address: {
          ipv4.addresses = [
            {
              address = address;
              prefixLength = 24;
            }
          ];
        })
        cfg.staticAddresses.interfaces
      );
      defaultGateway = lib.mkIf cfg.staticAddresses.enable cfg.staticAddresses.defaultGateway;
      nameservers = ["8.8.8.8" "1.1.1.1"];
    };

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      publish = lib.mkIf cfg.staticAddresses.enable {
        enable = true;
        hinfo = true;
        addresses = true;
        workstation = true;
      };
      openFirewall = true;
    };
  };
}
