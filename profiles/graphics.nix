{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.site.profiles.graphics;
in {
  options.site.profiles.graphics = {
    enable = lib.mkEnableOption "graphics profile (GUI and display settings)";
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth.enable = true;

    services.xserver = {
      enable = true;
      displayManager.startx.enable = true;
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal
        xdg-desktop-portal-gtk
      ];
    };
  };
}
