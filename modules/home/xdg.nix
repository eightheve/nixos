{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homeModules.xdg;

  browser = ["librewolf.desktop"];

  associations = {
    "application/x-extension-htm" = browser;
    "application/x-extension-html" = browser;
    "application/x-extension-shtml" = browser;
    "application/x-extension-xht" = browser;
    "application/x-extension-xhtml" = browser;
    "application/xhtml+xml" = browser;
    "text/html" = browser;
    "x-scheme-handler/about" = browser;
    "x-scheme-handler/chrome" = ["chromium-browser.desktop"];
    "x-scheme-handler/ftp" = browser;
    "x-scheme-handler/http" = browser;
    "x-scheme-handler/https" = browser;
    "x-scheme-handler/unknown" = browser;

    "audio/*" = ["mpv.desktop"];
    "video/*" = ["mpv.desktop"];
    "image/*" = ["imv.desktop"];
    "application/json" = browser;
    "application/pdf" = ["mupdf.desktop"];
    "x-scheme-handler/discord" = ["equibop.desktop"];
  };
in {
  options.homeModules.xdg.enable = lib.mkEnableOption "xdg portals";

  config = lib.mkIf cfg.enable {
    xdg = {
      enable = true;
      cacheHome = "${config.home.homeDirectory}/.local/cache";

      mimeApps = {
        enable = true;
        defaultApplications = associations;
      };

      portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal
          xdg-desktop-portal-hyprland
          xdg-desktop-portal-gtk
        ];
        config.common.default = "*";
      };

      userDirs = {
        enable = true;
        createDirectories = true;
        download = "${config.home.homeDirectory}/Downloads";
        documents = "${config.home.homeDirectory}/Resources/Documents";
        music = "${config.home.homeDirectory}/Resources/Music";
        pictures = "${config.home.homeDirectory}/Resources/Pictures";
        videos = "${config.home.homeDirectory}/Resources/Videos";
        templates = "${config.home.homeDirectory}/Resources/Templates";
        extraConfig = {
          XDG_SCREENSHOTS_DIR = "${config.xdg.userDirs.pictures}/Screenshots";
        };
      };
    };
  };
}
