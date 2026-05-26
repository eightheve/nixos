{
  config,
  lib,
  ...
}: let
  cfg = config.site.profiles.desktop;
in {
  options.site.profiles.desktop = {
    enable = lib.mkEnableOption "desktop profile (workstation GUI settings)";
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth.enable = true;

    services.xserver = {
      enable = true;
      displayManager.startx.enable = true;
    };
  };
}
