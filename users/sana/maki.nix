{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
# The fold plugin: maki patched with the fold-tag surgery plus the Lua side
# (set_tag / fold / return_to_tag). Takes over ~/.config/maki/init.lua and
# both plugin files; plugin.toml stays hand-maintained.
let
  cfg = config.site.users.sana;

  makiPatched = import ../../packages/maki.nix {
    inherit pkgs lib;
    maki = inputs.maki.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

  initLua = ''
    require("fine-scroll")
    require("fold")
  '';

  # Shared by every user running the patched maki. plugin.toml is an empty
  # marker maki expects inside a plugin dir; it carries no grants.
  makiFiles = {
    ".config/maki/init.lua".text = initLua;
    ".config/maki/lua/fine-scroll.lua".source = ./maki-lua/fine-scroll.lua;
    ".config/maki/lua/fold.lua".source = ./maki-lua/fold.lua;
  };
in
{
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      hjem.users.sana = {
        packages = [ makiPatched ];
        files = makiFiles;
      };
    })

    (lib.mkIf (cfg.enable && cfg.agent.enable) {
      hjem.users.${cfg.agent.userName} = {
        packages = [ makiPatched ];
        files = makiFiles // {
          ".config/maki/plugin.toml".text = "";
        };
      };
    })
  ];
}
