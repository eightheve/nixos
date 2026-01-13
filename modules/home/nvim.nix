{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.homeModules.nvim;
in {
  imports = [inputs.nvf.homeManagerModules.default];

  options.homeModules.nvim = {
    enable = lib.mkEnableOption "nvim powered by nvf";
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables.EDITOR = "nvim";

    programs.nvf = {
      enable = true;

      settings.vim = {
        viAlias = true;
        vimAlias = true;

        clipboard = {
          enable = true;
          providers.wl-copy.enable = true;
        };

        options = {
          shiftwidth = 2;
          expandtab = true;
        };

        globals.maplocalleader = " ";
        hideSearchHighlight = true;
        git.enable = true;

        statusline.lualine.enable = true;
        telescope.enable = true;
        autocomplete.nvim-cmp.enable = true;

        lsp = {
          enable = true;
          formatOnSave = true;
        };

        languages = {
          enableDAP = true;
          #enableTreesitter = true;
          enableFormat = true;

          nix.enable = true;
          bash.enable = true;
          html.enable = true;
          css.enable = true;
          clojure.enable = true;
        };

        repl.conjure.enable = true;

        binds = {
          whichKey.enable = true;
        };
      };
    };
  };
}
