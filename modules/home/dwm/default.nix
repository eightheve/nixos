{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homeModules.windowManagers.dwm;

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

  mkSlstatusConfig = {
    modules,
    interval ? 1000,
    unknown_str ? "n/a",
  }: let
    mkModule = {
      function,
      format,
      argument,
    }: ''{ ${function}, "${format}", "${argument}" }'';

    modulesStr = lib.concatStringsSep ",\n\t" (map mkModule modules);
  in ''
    const unsigned int interval = ${toString interval};
    static const char unknown_str[] = "${unknown_str}";
    #define MAXLEN 2048

    static const struct arg args[] = {
    	${modulesStr}
    };
  '';

  playerctlScript = pkgs.writeShellScript "get-current-media" ''
    status=$(${pkgs.playerctl}/bin/playerctl status 2>/dev/null)

    if [[ "$status" == "Playing" || "$status" == "Paused" ]]; then
      artist=$(${pkgs.playerctl}/bin/playerctl metadata artist 2>/dev/null)
      title=$(${pkgs.playerctl}/bin/playerctl metadata title 2>/dev/null)
      echo " PLAY: $title - $artist |"
    else
      echo ""
    fi
  '';
in {
  options.homeModules.windowManagers.dwm = {
    enable = lib.mkEnableOption "dwm";

    makeXinitrc = lib.mkOption {
      type = lib.types.bool;
      default = true;
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
    ];

    systemd.user.services.slstatus = {
      Unit = {
        Description = "slstatus for dwm";
      };

      Service = {
        ExecStart = "${pkgs.slstatus.override {
          conf = mkSlstatusConfig {
            interval = 1000;
            unknown_str = "";
            modules = [
              {
                function = "ipv4";
                format = " NET: %s |";
                argument = "wlp4s0";
              }
              {
                function = "run_command";
                format = "%s";
                argument = "${playerctlScript}";
              }
              {
                function = "ram_perc";
                format = " MEM: %s%% |";
                argument = "";
              }
              {
                function = "temp";
                format = " TMP: %s°C |";
                argument = "/sys/class/thermal/thermal_zone0/temp";
              }
              {
                function = "battery_perc";
                format = " BAT: %s%% ";
                argument = "BAT0";
              }
              {
                function = "battery_state";
                format = "%s |";
                argument = "BAT0";
              }
              {
                function = "keymap";
                format = " %s |";
                argument = "";
              }
              {
                function = "datetime";
                format = " %s ";
                argument = "%a %d %b %T";
              }
            ];
          };
        }}/bin/slstatus";
        Restart = "always";
        Environment = [
          "DISPLAY=:0"
          "XAUTHORITY=${config.home.homeDirectory}/.Xauthority"
        ];
        BindReadOnlyPaths = ["/sys"];
      };
    };

    home.pointerCursor = {
      gtk.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Original-Classic";
      size = 24;
    };

    home.file.".xinitrc".text = lib.mkIf cfg.makeXinitrc ''
      systemctl --user start slstatus &
      ${lib.concatStringsSep "\n" cfg.additionalInitCommands}
      exec dwm
    '';
  };
}
