{
  pkgs,
  lib,
  isLaptop ? false,
}:
let
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
      alertFrameOne = "|             ";
      alertFrameTwo = "| ***POWER*** ";
    in
      pkgs.writeShellScript "batteryAlert" ''
        if [ "$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/BAT0/capacity)" -lt 15 ]; then
          if (("$(${pkgs.coreutils}/bin/date +%-S)" & 2)); then
            echo "${alertFrameOne}"
          else
            echo "${alertFrameTwo}"
          fi
        fi
      '';
  };

  baseModules = [
    { function = "run_command"; format = "%s"; argument = "${scripts.nowPlaying}"; }
    { function = "ram_perc"; format = " MEM: %s%% |"; argument = ""; }
    { function = "temp"; format = " TMP: %s°C |"; argument = "/sys/class/thermal/thermal_zone0/temp"; }
    { function = "keymap"; format = " %s |"; argument = ""; }
    { function = "run_command"; format = " V: %s"; argument = "${scripts.currentVolume}"; }
    { function = "run_command"; format = "%s |"; argument = "${scripts.muteStatus}"; }
    { function = "datetime"; format = " %s "; argument = "%a %d %b %T"; }
  ];

  laptopModules = [
    { function = "ipv4"; format = " NET: %s |"; argument = "wlp4s0"; }
    { function = "battery_perc"; format = " BAT: %s%% "; argument = "BAT0"; }
    { function = "battery_state"; format = "%s |"; argument = "BAT0"; }
    { function = "run_command"; format = " B: %s"; argument = "${scripts.currentBrightness}"; }
    { function = "run_command"; format = "%s"; argument = "${scripts.batteryAlert}"; }
  ];

  modules = baseModules ++ lib.optionals isLaptop laptopModules;

  mkSlstatusConfig = moduleList: let
    mkModule = { function, format, argument }: ''{ ${function}, "${format}", "${argument}" }'';
    modulesStr = lib.concatStringsSep ",\n\t" (map mkModule moduleList);
  in ''
    const unsigned int interval = 1000;
    static const char unknown_str[] = "";
    #define MAXLEN 2048

    static const struct arg args[] = {
    	${modulesStr}
    };
  '';
in
  pkgs.slstatus.override {
    conf = mkSlstatusConfig modules;
  }
