{
  config,
  lib,
  ...
}: let
  cfg = config.site.profiles.laptop;
in {
  options.site.profiles.laptop = {
    enable = lib.mkEnableOption "laptop profile (mobile hardware and display settings)";
  };

  config = lib.mkIf cfg.enable {
    hardware = {
      bluetooth.enable = true;
      sensor.iio.enable = true;
    };

    services.xserver = {
      enable = true;
      displayManager.startx.enable = true;
      videoDrivers = ["modesetting"];
    };
  };
}
