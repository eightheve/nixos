{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.myModules.vintagestoryOverlay;
in {
  options.myModules.vintagestoryOverlay = {
    enable = lib.mkEnableOption "overlay for vintagestory-nix. should only enable if using vintagestory-nix elsewhere, otherwise useless";
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [inputs.vintagestory-nix.overlays.default];
    nixpkgs.config.permittedInsecurePackages = [
      "dotnet-runtime-7.0.20"
    ];
  };
}
