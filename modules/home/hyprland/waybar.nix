{config, ...}: let
  commonConfig = {
    height = 36;
    layer = "top";
    position = "top";
    margin = "0 0 0";
    spacing = 8;
  };
in {
  programs.waybar = {
    enable = true;
    settings = {
      mainBar =
        commonConfig
        // {
          output = "DP-2";
          modules-left = [
            "hyprland/workspaces"
          ];
          modules-center = [
            "custom/waybar-mpris"
          ];
          modules-right = [
            "pulseaudio"
            "bluetooth"
          ];
          "pulseaudio" = {
            format = "{volume}% {icon}";
            max-volume = 150;
            scroll-step = 10;
            format-icons = {
              default = "";
              default-muted = "";
            };
            on-click = "pavucontrol";
          };
          "hyprland/workspaces" = {
            format = "{id}: {icon}";
            format-icons = {
              default = "󰍹";
              active = "󱩛";
            };
          };
          "custom/waybar-mpris" = {
            return-type = "json";
            escape = true;
            exec = "waybar-mpris --pause '' --play ''";
            on-click = "waybar-mpris --send toggle";
            on-scroll-up = "waybar-mpris --send next";
            on-scroll-down = "waybar-mpris --send prev";
          };
          bluetooth = {
            format-off = "󰂲";
            format-on = "󰂯";
            format-connected = "󰂱";
            on-click = "bluetoothctl power on";
            on-click-middle = "bluetoothctl devices Connected | awk '{print $2}' | xargs -I {} bluetoothctl disconnect {}";
            on-click-right = "bluetoothctl power off";
            tooltip = true;
            tooltip-format-off = "Bluetooth controller off";
            tooltip-format-on = "Bluetooth controller on";
            tooltip-format-connected = "Connected to {num_connections} devices {device_enumerate}";
          };
        };
      leftBar =
        commonConfig
        // {
          output = "HDMI-A-1";
          modules-left = [
            "memory"
            "cpu"
            "temperature"
          ];
          modules-center = [
            "clock#time"
            "clock#date"
          ];
          modules-right = [
            "network"
            "idle_inhibitor"
          ];

          "clock#time" = {
            interval = 1;
            tooltip = true;
            format = "{:%H:%M }";
            tooltip-format = "{:%T}";
          };
          "clock#date" = {
            interval = 60;
            tooltip = true;
            format = "{:%a %d }";
            tooltip-format = "{:%Y-%m-%d}";
          };
          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = "";
              deactivated = "";
            };
          };
          network = {
            format = "{bandwidthDownBytes} 󰖩";
            format-alt = "{essid} 󰖩";
            format-disconnected = "󰖪";
          };
          memory = {
            interval = 10;
            format = "{percentage}% ";
          };
          cpu = {
            interval = 5;
            format = "{usage}% ";
          };
          temperature = {
            hwmon-path = "/sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon3/temp1_input";
            format = "{temperatureC}° ";
            tooltip = false;
          };
        };
    };
    style = ''
      *{
        font-family: "JetBrainsMono Nerd Font";
        font-weight: bold;
        font-size: 14px;
        color: #${config.colorScheme.colors.shade5};
      }

      .modules-right {
        padding-right: 8px;
      }
      .modules-left {
        padding-left: 8px;
      }

      window {
        background-color: #${config.colorScheme.colors.shade0};
        border-radius: 0;
        border-bottom: 2px solid #${config.colorScheme.colors.shade1};
      }

      .module {
        padding: 0 8px;
      }

      #pulseaudio-slider {
        min-width: 128px;
        padding: 0 12px;
      }
      #pulseaudio-slider slider {
        min-width: 8px;
      }
      #pulseaudio-slider trough {
        background-color: #${config.colorScheme.colors.shade2};
      }
      #pulseaudio-slider highlight {
        background-color: #${config.colorScheme.colors.shade4};
      }

      #clock { min-width: 48px; }
      #idle_inhibitor { min-width: 24px; padding: 0 7px 0 0; }
      #cpu { min-width: 34px; }
      #memory { min-width: 34px; }
      #temperature { min-width: 34px; }
      #custom-waybar-mpris { min-width: 128px; }
    '';
  };
}
