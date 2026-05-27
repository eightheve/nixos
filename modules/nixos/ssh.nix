{
  config,
  lib,
  ...
}: let
  cfg = config.site.modules.ssh;
in {
  options.site.modules.ssh = {
    enable = lib.mkEnableOption "ssh";
    openFirewall = lib.mkEnableOption "open ports in firewall";

    ports = lib.mkOption {
      type = lib.types.listOf lib.types.int;
      default = [22];
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = cfg.ports;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall cfg.ports;
  };
}
