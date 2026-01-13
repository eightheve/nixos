{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.myModules.sanaWebsite;
in {
  options.myModules.sanaWebsite = {
    enable = lib.mkEnableOption "sana's website";

    settings = {
      environmentFilePath = lib.mkOption {
        type = lib.types.str;
        default = "/etc/sana-doppel-moe.env";
      };

      localPort = lib.mkOption {
        type = lib.types.int;
        default = 3200;
      };
    };
  };

  imports = [
    inputs.sana-website.nixosModules.default
  ];

  config = lib.mkIf cfg.enable {
    services.sana-moe = {
      enable = true;
      envFile = cfg.settings.environmentFilePath;
      localPort = cfg.settings.localPort;
    };
  };
}
