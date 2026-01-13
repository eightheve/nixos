{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homeModules.supersonic;
  colors = config.colorScheme.colors;
  isDark = colors.meta.style == "dark";

  toTomlValue = value:
    if builtins.isString value
    then ''"${value}"''
    else if builtins.isBool value
    then
      (
        if value
        then "true"
        else "false"
      )
    else builtins.toString value;

  mkSedCommands = settings: configPath: let
    sedCommands = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        key: value:
        # Use | as delimiter instead of /
        "$DRY_RUN_CMD sed -i 's|^${key} = .*|${key} = ${toTomlValue value}|' \"${configPath}\""
      )
      settings
    );
  in
    sedCommands;
in {
  options.homeModules.supersonic = {
    enable = lib.mkEnableOption "supersonic music player";

    settings = {
      fontPaths = {
        normal = lib.mkOption {
          type = lib.types.str;
          default = "";
        };

        bold = lib.mkOption {
          type = lib.types.str;
          default = "";
        };
      };

      useCustomTheme = lib.mkEnableOption "enable custom theming, must also have colorSchemes.enable set to true.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      supersonic
    ];

    home.activation.updateSupersonic = lib.hm.dag.entryAfter ["writeBoundary"] (
      let
        customThemeEnabled = cfg.settings.useCustomTheme && config.colorScheme.enable;
        declarativeSettings = {
          ThemeFile =
            if customThemeEnabled
            then "custom.toml"
            else "";
          Appearance =
            if (customThemeEnabled && !isDark)
            then "Light"
            else "Dark";
          FontNormalTTF = "${cfg.settings.fontPaths.normal}";
          FontBoldTTF = "${cfg.settings.fontPaths.bold}";
        };
        configPath = "$HOME/.config/supersonic/config.toml";
      in ''
        ${mkSedCommands declarativeSettings configPath}
      ''
    );

    home.file.".config/supersonic/themes/custom.toml".text = lib.mkIf (cfg.settings.useCustomTheme && config.colorScheme.enable) ''
      [SupersonicTheme]
      Name = "${colors.meta.name}"
      Version = "0.2"
      SupportsDark = ${
        if isDark
        then "true"
        else "false"
      }
      SupportsLight = ${
        if isDark
        then "false"
        else "true"
      }

      ${
        if isDark
        then "[DarkColors]"
        else "[LightColors]"
      }
      PageBackground = "#${colors.shade0}"
      Foreground = "#${colors.shade5}"
      InputBackground = "#${colors.shade1}"
      InputBorder = "#00000000"
      MenuBackground = "#${colors.shade1}"
      OverlayBackground = "#${colors.shade1}"
      Pressed = "#${colors.shade2}"
      Hyperlink = "#${colors.shade4}"
      ListHeader = "#${colors.shade1}"
      PageHeader = "#${colors.shade1}"
      Background = "#${colors.shade1}"
      ScrollBar = "#${colors.shade3}"
      Button = "#${colors.shade2}"
      DisabledButton = "#${colors.shade1}"
      Disabled = "#${colors.shade3}"
      Error = "#${colors.accent0."${
        if isDark
        then "1"
        else "0"
      }"}"
      Focus = "#${colors.shade2}"
      Placeholder = "#${colors.shade4}"
      Primary = "#${colors.accent4."${
        if isDark
        then "1"
        else "0"
      }"}"
      Hover = "#${colors.shade2}"
      Separator = "#00000000"
      Shadow = "0000005c"
      Success = "#${colors.accent2."${
        if isDark
        then "1"
        else "0"
      }"}"
      Warning = "#${colors.accent3."${
        if isDark
        then "1"
        else "0"
      }"}"
    '';
  };
}
