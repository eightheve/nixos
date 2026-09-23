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
in
{
  config = lib.mkIf cfg.enable {
    hjem.users.sana = {
      packages = [ makiPatched ];

      files = {
        ".config/maki/init.lua".text = initLua;
        ".config/maki/lua/fine-scroll.lua".source = ./maki-lua/fine-scroll.lua;
        ".config/maki/lua/fold.lua".source = ./maki-lua/fold.lua;
      };
    };
  };
}
