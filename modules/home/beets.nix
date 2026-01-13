{
  config,
  lib,
  ...
}: let
  cfg = config.homeModules.beets;
in {
  options.homeModules.beets = {
    enable = lib.mkEnableOption "beets music manager";

    settings = {
      musicPath = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/Music";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.beets = {
      enable = true;
      settings = {
        directory = cfg.settings.musicPath;
        import = {
          move = "yes";
        };
        original_date = "yes";
        plugins = "scrub missing ftintitle";
        ftintitle = {
          auto = "yes";
        };
      };
    };
  };
}
