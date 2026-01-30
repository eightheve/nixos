{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homeModules.suckless.slstatus;

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

  scripts = {
    nowPlaying = pkgs.writeShellScript "nowPlaying" ''
      status=$(${pkgs.playerctl}/bin/playerctl status 2>/dev/null)

      if [[ "$status" == "Playing" || "$status" == "Paused" ]]; then
        artist=$(${pkgs.playerctl}/bin/playerctl metadata artist 2>/dev/null)
        title=$(${pkgs.playerctl}/bin/playerctl metadata title 2>/dev/null)
        echo " PLAY: $title - $artist |"
      else
        echo ""
      fi
    '';

    currentBrightness = pkgs.writeShellScript "currentBrightness" ''
      echo $(($(${pkgs.brightnessctl}/bin/brightnessctl g -e) * 100 / $(${pkgs.brightnessctl}/bin/brightnessctl m -e)))%
    '';

    currentVolume = pkgs.writeShellScript "currentVolume" ''
      ${pkgs.pulseaudio}/bin/pactl get-sink-volume @DEFAULT_SINK@ | ${pkgs.gnugrep}/bin/grep -oP '\d+%' | ${pkgs.coreutils}/bin/head -1
    '';

    muteStatus = pkgs.writeShellScript "muteStatus" ''
      [[ $(${pkgs.pulseaudio}/bin/pactl get-sink-mute @DEFAULT_SINK@) == "Mute: yes" ]] && echo " (M)" || echo ""
    '';

    batteryAlert = let
      alertFrameOne = " ";
      alertFrameTwo = " ";
    in
      pkgs.writeShellScript " " ''
        if [ "$(cat /sys/class/power_supply/BAT0/capacity)" -lt 15 ]; then
          if (("$(date +%-S)" & 2)); then
            echo "${alertFrameOne}"
          else
            echo "${alertFrameTwo}"
          fi
        fi
      '';
  };
in {
  options.homeModules.suckless.slstatus = {
    enable = lib.mkEnableOption "slstatus";

    modules = lib.mkOption {
      type = with lib.types;
        listOf (submodule {
          options = {
            function = lib.mkOption {type = str;};
            format = lib.mkOption {type = str;};
            argument = lib.mkOption {type = str;};
          };
        });
      default = [
        {
          function = "ipv4";
          format = " NET: %s |";
          argument = "wlp4s0";
        }
        {
          function = "run_command";
          format = "%s";
          argument = "${scripts.nowPlaying}";
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
          function = "run_command";
          format = " B: %s";
          argument = "${scripts.currentBrightness}";
        }
        {
          function = "run_command";
          format = " V: %s";
          argument = "${scripts.currentVolume}";
        }
        {
          function = "run_command";
          format = "%s |";
          argument = "${scripts.muteStatus}";
        }
        {
          function = "datetime";
          format = " %s ";
          argument = "%a %d %b %T";
        }
        {
          function = "run_command";
          format = "%s";
          argument = "${scripts.batteryAlert}";
        }
      ];
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.slstatus.override {
        conf = mkSlstatusConfig {
          interval = 1000;
          unknown_str = "";
          modules = cfg.modules;
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.slstatus = {
      Unit = {
        Description = "slstatus";
      };

      Service = {
        ExecStart = "${cfg.package}/bin/slstatus";
        Restart = "always";
        Environment = [
          "XDG_RUNTIME_DIR=/run/user/1000"
          "DISPLAY=:0"
          "XAUTHORITY=${config.home.homeDirectory}/.Xauthority"
        ];
        BindReadOnlyPaths = ["/sys"];
      };
    };
  };
}
