{
  config,
  lib,
  ...
}: let
  cfg = config.homeModules.fish;
in {
  options.homeModules.fish = {
    enable = lib.mkEnableOption "friendly interactive shell";

    settings = {
      editorCommand = lib.mkOption {
        type = lib.types.str;
        default =
          if config.homeModules.nvim.enable
          then "nvim"
          else "nano";
      };

      useGitStatus = lib.mkEnableOption "enable advanced git statuses, like showing if there is uncommited changes";

      promptColors = {
        hostName = lib.mkOption {
          type = lib.types.str;
          default = "normal";
          description = "Can be a color name like 'red' or a hex value like '14ab34'";
        };

        remoteHost = lib.mkOption {
          type = lib.types.str;
          default = "yellow";
          description = "Can be a color name like 'red' or a hex value like '14ab34'";
        };

        userName = lib.mkOption {
          type = lib.types.str;
          default = "brgreen";
          description = "Can be a color name like 'red' or a hex value like '14ab34'";
        };

        filePath = lib.mkOption {
          type = lib.types.str;
          default = "green";
          description = "Can be a color name like 'red' or a hex value like '14ab34'";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        set -g EDITOR ${cfg.settings.editorCommand}

        set -g fish_color_host ${cfg.settings.promptColors.hostName}
        set -g fish_color_host_remote ${cfg.settings.promptColors.remoteHost}
        set -g fish_color_user ${cfg.settings.promptColors.userName}
        set -g fish_color_cwd ${cfg.settings.promptColors.filePath}
      '';
    };
  };
}
