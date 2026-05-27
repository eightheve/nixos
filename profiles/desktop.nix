{
  config,
  lib,
  ...
}: let
  cfg = config.site.profiles.desktop;
in {
  options.site.profiles.desktop = {
    enable = lib.mkEnableOption "desktop profile (workstation-specific settings)";
  };

  config = lib.mkIf cfg.enable {
    site.profiles.graphics.enable = true;
  };
}
