{
  config,
  lib,
  ...
}:
{
  options.site.colorScheme = {
    enable = lib.mkEnableOption "color scheme configuration";

    path = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };

    colors = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.str (lib.types.attrsOf lib.types.str));
      default = { };
      description = "color values from scheme file";
    };

  };

  config = lib.mkMerge [
    (lib.mkIf config.site.colorScheme.enable {
      assertions = [
        {
          assertion = config.site.colorScheme.path != null;
          message = "site.colorScheme.path must be set when site.colorScheme.enable is true";
        }
      ];
    })

    (lib.mkIf (config.site.colorScheme.enable && config.site.colorScheme.path != null) {
      site.colorScheme.colors =
        let
          scheme = import config.site.colorScheme.path;
          requiredShades = [
            "shade0"
            "shade1"
            "shade2"
            "shade3"
            "shade4"
            "shade5"
          ];
          requiredAccents = [
            "accent0"
            "accent1"
            "accent2"
            "accent3"
            "accent4"
            "accent5"
            "accent6"
            "accent7"
          ];

          validateShade = name: lib.assertMsg (scheme ? ${name}) "Missing required shade: ${name}";
          validateAccent =
            name:
            lib.assertMsg (
              scheme ? ${name} && scheme.${name} ? "0" && scheme.${name} ? "1"
            ) "Accent ${name} must have both '0' (dark) and '1' (light) variants";

          validShades = builtins.all validateShade requiredShades;
          validAccents = builtins.all validateAccent requiredAccents;
        in
        assert validShades;
        assert validAccents;
        scheme;
    })
  ];
}
