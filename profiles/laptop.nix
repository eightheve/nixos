{
  config,
  lib,
  ...
}: let
  cfg = config.site.profiles.laptop;
in {
  options.site.profiles.laptop = {
    enable = lib.mkEnableOption "laptop profile (mobile hardware settings)";
  };

  config = lib.mkIf cfg.enable {
    site.profiles.graphics.enable = true;

    hardware.sensor.iio.enable = true;

    services.xserver.videoDrivers = ["modesetting"];
  };
}
