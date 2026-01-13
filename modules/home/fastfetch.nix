{
  config,
  lib,
  ...
}: {
  options.homeModules.fastfetch = {
    enable = lib.mkEnableOption "fastfetch";
  };

  config = lib.mkIf config.homeModules.fastfetch.enable {
    programs.fastfetch = {
      enable = true;
      settings = let
        greenKey = icon: {
          key = "  ${icon} ";
          keyColor = "green";
        };

        blueKey = icon: {
          key = "  ${icon} ";
          keyColor = "blue";
        };

        header = text: {
          type = "custom";
          color = "blue";
          format = text;
        };
      in {
        display.separator = " ";
        logo.padding.top = 0;

        modules = [
          (header "┌─── OS Information ──────────────────────────┐")
          "break"

          ({
              type = "title";
              color = {
                host = "green";
                user = "green";
              };
            }
            // greenKey "󰏩")

          ({type = "os";} // greenKey "󰇖")
          ({type = "kernel";} // greenKey "󰻀")
          ({type = "packages";} // greenKey "󱁤")
          ({type = "shell";} // greenKey "󰆍")
          ({type = "uptime";} // greenKey "󰔚")

          "break"
          (header "├─── Hardware Information ────────────────────┤")
          "break"

          ({type = "host";} // blueKey "󰌢")

          ({
              type = "cpu";
              format = "{packages} x {name}";
            }
            // blueKey "󰘚")

          {
            type = "cpu";
            key = "  └";
            keyColor = "blue";
            format = "{cores-physical} Cores ({cores-online} Threads) @ {freq-max}";
          }

          ({type = "gpu";} // blueKey "󰘚")
          ({type = "memory";} // blueKey "󰍛")
          ({type = "disk";} // blueKey "󱛟")

          "break"

          {
            type = "custom";
            keyColor = "blue";
            format = "└─────────────────────────────────────────────┘";
          }
        ];
      };
    };
  };
}
