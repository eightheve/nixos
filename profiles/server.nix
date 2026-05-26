{
  config,
  lib,
  ...
}: let
  cfg = config.site.profiles.server;
in {
  options.site.profiles.server = {
    enable = lib.mkEnableOption "server profile (headless server base settings)";
  };

  config = lib.mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;
      defaults.email = "sana@doppel.moe";
    };

    myModules.ssh = {
      enable = true;
      openFirewall = true;
    };
  };
}
