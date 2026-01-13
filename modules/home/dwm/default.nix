{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homeModules.windowManagers.dwm;

  babashka-status-bar = pkgs.writeShellScriptBin "babashka-status-bar" ''
    ${pkgs.babashka}/bin/bb ${./status-bar.bb.clj} $@
  '';

  terminal =
    if config.homeModules.kitty.enable
    then "${pkgs.kitty}/bin/kitty"
    else "${pkgs.st}/bin/st";

  colorCfg = config.colorScheme;
  colors =
    if colorCfg.enable
    then {
      gray1 = "${colorCfg.colors.shade0}";
      gray2 = "${colorCfg.colors.shade2}";
      gray3 = "${colorCfg.colors.shade3}";
      gray4 = "${colorCfg.colors.shade5}";
      accent1 = "${colorCfg.colors.accent4."0"}";
      accent2 = "${colorCfg.colors.accent4."1"}";
    }
    else {
      gray1 = "000000";
      gray2 = "181818";
      gray3 = "e1e1e1";
      gray4 = "ffffff";
      accent1 = "222244";
      accent2 = "444477";
    };
in {
  options.homeModules.windowManagers.dwm = {
    enable = lib.mkEnableOption "dwm";

    makeXinitrc = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    babashkaStatus = {
      enable = lib.mkEnableOption "use the babashka-status-bar script";

      monitors = lib.mkOption {
        type = lib.types.str;
        default = "memory wifi temperature battery time-with-compute";
      };
    };

    additionalInitCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "A list of additional commands to write to ~/.xinitrc";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      (dwm.overrideAttrs (oldAttrs: {
        #patches = [
        #  ./patches/
        #];
        postPatch = ''
          cp ${./config.h} config.def.h
          substituteInPlace config.def.h \
            --replace-fail "@TERMCMD@" "${terminal}" \
            --replace-fail "@GRAY_1@" "${colors.gray1}" \
            --replace-fail "@GRAY_2@" "${colors.gray2}" \
            --replace-fail "@GRAY_3@" "${colors.gray3}" \
            --replace-fail "@GRAY_4@" "${colors.gray4}" \
            --replace-fail "@ACCENT1@" "${colors.accent1}" \
            --replace-fail "@ACCENT2@" "${colors.accent2}"
        '';
      }))
      dmenu
      st
      feh
      acpi
      iw
    ];

    home.pointerCursor = {
      gtk.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Original-Classic";
      size = 24;
    };

    home.file.".xinitrc".text = lib.mkIf cfg.makeXinitrc ''
      ${lib.optionalString cfg.babashkaStatus.enable "${babashka-status-bar}/bin/babashka-status-bar run dwm ${cfg.babashkaStatus.monitors} &"}
      ${lib.concatStringsSep "\n" cfg.additionalInitCommands}
      exec dwm
    '';
  };
}
