{
  config,
  lib,
  ...
}: let
  cfg = config.site.modules.zsh;
in {
  options.site.modules.zsh = {
    enable = lib.mkEnableOption "zsh + omz";
  };

  config = lib.mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      autosuggestions.enable = true;
      ohMyZsh = {
        enable = true;
        theme = "fishy";
        plugins = [
          "git"
        ];
      };
    };
  };
}
