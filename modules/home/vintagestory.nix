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

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs ? vintagestoryPackages;
        message = "vintagestoryPackages not found in pkgs. Add the vintagestory-nix overlay to your nixpkgs.overlays";
      }
    ];
    nixpkgs.overlays = [inputs.vintagestory-nix.overlays.default];

    programs.vs-launcher = {
      enable = true;
      settings.gameVersions = map (v: config.nixpkgs.pkgs.vintagestoryPackages.${v}) cfg.versions;
    };
  };
}
