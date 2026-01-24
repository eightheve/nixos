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

    enableProseSupport = lib.mkEnableOption "vale + null-ls + alex";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
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
    })
    (lib.mkIf (cfg.enable && cfg.enableProseSupport) {
      home.packages = with pkgs; [
        vale
        valeStyles.alex
        valeStyles.proselint
      ];

      home.file.".vale.ini".text = ''
        StylesPath = styles
        MinAlertLevel = suggestion

        Packages = alex, proselint
        [*.{md,txt}]
        BasedOnStyles = alex, proselint
      '';

      programs.nvf.settings.vim = {
        extraPlugins = {
          null-ls = {
            package = pkgs.vimPlugins.none-ls-nvim;
            setup = ''
              require('null-ls').setup({
                sources = {
                  require('null-ls').builtins.diagnostics.vale,
                },
              })
            '';
          };
        };

        maps.normal."<leader>p" = {
          action = ":lua ToggleProse()<CR>";
          silent = true;
        };

        luaConfigRC.prose-toggle = ''
          _G.prose_mode = false

          function ToggleProse()
            _G.prose_mode = not _G.prose_mode

            if _G.prose_mode then
              vim.opt_local.wrap = true
              vim.opt_local.linebreak = true
              vim.opt_local.breakindent = true
              vim.opt_local.spell = true
              vim.keymap.set({'n', 'v'}, 'j', 'gj', {buffer = true, silent = true})
              vim.keymap.set({'n', 'v'}, 'k', 'gk', {buffer = true, silent = true})
              print("Prose mode enabled")
            else
              vim.opt_local.wrap = true
              vim.opt_local.linebreak = false
              vim.opt_local.spell = false
              vim.keymap.del({'n', 'v'}, 'j', {buffer = true})
              vim.keymap.del({'n', 'v'}, 'k', {buffer = true})
              print("Prose mode disabled")
            end
          end
        '';
      };
    })
  ];
}
