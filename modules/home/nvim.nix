{
  config,
  lib,
  inputs,
  pkgs,
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
    home.packages = [
      pkgs.mitscheme
    ];

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
          tabstop = 2;
          softtabstop = 2;
          autoindent = true;
          smartindent = true;
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

        treesitter = {
          enable = true;
          addDefaultGrammars = true;
          indent.enable = false;
          grammars = pkgs.vimPlugins.nvim-treesitter.allGrammars;
        };

        languages = {
          enableDAP = true;
          enableTreesitter = true;
          enableFormat = true;

          nix = {
            enable = true;
            treesitter.enable = true;
          };
          bash.enable = true;
          html = {
            enable = true;
            treesitter.enable = true;
          };
          css = {
            enable = true;
            treesitter.enable = true;
          };
          clang = {
            enable = true;
            treesitter.enable = true;
          };
          clojure = {
            enable = true;
            treesitter.enable = true;
          };
        };

        repl.conjure.enable = true;

        binds = {
          whichKey.enable = true;
        };
      };
    };
  };
}
