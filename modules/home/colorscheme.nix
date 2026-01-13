{
  config,
  lib,
  ...
}: {
  options.colorScheme = {
    enable = lib.mkEnableOption "color scheme configuration";

    path = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };

    colors = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.str (lib.types.attrsOf lib.types.str));
      default = {};
      description = "color values from scheme file";
    };

    termColors = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "ANSI terminal color mappings (color00-color15)";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.colorScheme.enable {
      assertions = [
        {
          assertion = config.colorScheme.path != null;
          message = "colorScheme.path must be set when colorScheme.enable is true";
        }
      ];
    })

    (lib.mkIf (config.colorScheme.enable && config.colorScheme.path != null) {
      colorScheme.colors = let
        scheme = import config.colorScheme.path;
        requiredShades = ["shade0" "shade1" "shade2" "shade3" "shade4" "shade5"];
        requiredAccents = ["accent0" "accent1" "accent2" "accent3" "accent4" "accent5" "accent6" "accent7"];

        validateShade = name: lib.assertMsg (scheme ? ${name}) "Missing required shade: ${name}";
        validateAccent = name:
          lib.assertMsg
          (scheme ? ${name} && scheme.${name} ? "0" && scheme.${name} ? "1")
          "Accent ${name} must have both '0' (dark) and '1' (light) variants";

        validShades = builtins.all validateShade requiredShades;
        validAccents = builtins.all validateAccent requiredAccents;
      in
        assert validShades;
        assert validAccents; scheme;

      colorScheme.termColors = let
        c = config.colorScheme.colors;
      in {
        color00 = c.shade0; # black
        color01 = c.accent0."0"; # red
        color02 = c.accent3."0"; # green
        color03 = c.accent2."0"; # yellow
        color04 = c.accent4."0"; # blue
        color05 = c.accent6."0"; # magenta
        color06 = c.accent5."0"; # cyan
        color07 = c.shade4; # white
        color08 = c.shade3; # bright black
        color09 = c.accent0."1"; # bright red
        color10 = c.accent3."1"; # bright green
        color11 = c.accent2."1"; # bright yellow
        color12 = c.accent4."1"; # bright blue
        color13 = c.accent6."1"; # bright magenta
        color14 = c.accent5."1"; # bright cyan
        color15 = c.shade5; # bright white
      };
    })
  ];
}
