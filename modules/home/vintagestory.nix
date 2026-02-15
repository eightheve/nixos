{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: let
  cfg = config.homeModules.games.vintagestory;
in {
  options.homeModules.games.vintagestory = {
    enable = lib.mkEnableOption "vintagestory";

    versions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["latest"];
    };
  };

  imports = [inputs.vintagestory-nix.homeModules.default];

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs ? vintagestoryPackages;
        message = "vintagestoryPackages not found in pkgs. Add the vintagestory-nix overlay to your nixpkgs.overlays";
      }
    ];

    programs.vs-launcher = {
      enable = true;
      settings.gameVersions = map (v: pkgs.vintagestoryPackages.${v}) cfg.versions;
    };
  };
}
