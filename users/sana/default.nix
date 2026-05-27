{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.site.users.sana;
  packages = import ../../packages;

  c = config.site.colorScheme;
  termColors = c.termColors;

  xinitrcText = ''
    ${lib.concatStringsSep "\n" cfg.additionalXinitrcCommands}
    slstatus &
    feh --bg-fill ~/.wallpaper.jpg &
    exec dwm
  '';

  gitConfigText = ''
    [user]
      name = doppelsana
      email = sana@doppel.moe
      signingKey = 64E2D72FF5BA8BEE12C16A3D57096169F7C8117C
    [gpg]
      program = ${pkgs.gnupg}/bin/gpg
    [commit]
      gpgSign = true
  '';

  xdgMimeAppsText = ''
    [Default Applications]
    application/x-extension-htm=librewolf.desktop
    application/x-extension-html=librewolf.desktop
    application/x-extension-shtml=librewolf.desktop
    application/x-extension-xht=librewolf.desktop
    application/x-extension-xhtml=librewolf.desktop
    application/xhtml+xml=librewolf.desktop
    text/html=librewolf.desktop
    x-scheme-handler/about=librewolf.desktop
    x-scheme-handler/chrome=chromium-browser.desktop
    x-scheme-handler/ftp=librewolf.desktop
    x-scheme-handler/http=librewolf.desktop
    x-scheme-handler/https=librewolf.desktop
    x-scheme-handler/unknown=librewolf.desktop
    audio/*=mpv.desktop
    video/*=mpv.desktop
    image/*=imv.desktop
    application/json=librewolf.desktop
    application/pdf=mupdf.desktop
  '';

  zshConfigText = ''
    autoload -U colors && colors

    HISTSIZE=10000
    SAVEHIST=10000
    setopt SHARE_HISTORY
    setopt HIST_IGNORE_DUPS

    bindkey -e

    gpg-connect-agent /bye
    if [ -z "$SSH_AUTH_SOCK" ]; then
      export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
    fi

    alias vim="TERM=linux vim"

    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    EDITOR=vim
  '';

  vimrc = ''
    colorscheme wildcharm
    syntax on
    filetype plugin on
    filetype indent on
    let mapleader = " "
    func! AsciiMode()
      syntax off
      setlocal virtualedit=all
      autocmd BufWritePre * :%s/\s\+$//e
    endfu
    com! AC call AsciiMode()
    let s:wrapenabled = 0
    function ToggleWrap()
      set wrap nolist
      if s:wrapenabled
        set nolinebreak
        unmap j
        unmap k
        unmap $
        unmap 0
        unmap ^
        let s:wrapenabled = 0
      else
        set linebreak
        nnoremap j gj
        nnoremap k gk
        nnoremap $ g$
        nnoremap 0 g0
        nnoremap ^ g^
        vnoremap j gj
        vnoremap k gk
        vnoremap $ g$
        vnoremap 0 g0
        vnoremap ^ g^
        let s:wrapenabled = 1
      endif
    endfu
    map <leader>w :call ToggleWrap()<CR>
    autocmd FileType markdown setlocal spell
    autocmd FileType markdown call ToggleWrap()
  '';
in {
  options.site.users.sana = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable and manage the 'sana' user";
    };

    wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };

    additionalXinitrcCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional commands in ~/.xinitrc before exec dwm";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      users.users.sana = {
        isNormalUser = true;
        createHome = true;
        description = "二葉さな";
        extraGroups = ["wheel" "networkmanager" "slskd" "input"];
        hashedPassword = "$y$j9T$aqLJPq7sjoh7G60UN.4dd1$Deb/3ODxhVw.Qd2uN.A0.QvOH8Oel9BF.ukD/aXnNd8";
        shell = pkgs.zsh;
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC1Mbo28yG2Oln+KLKYp84MI/4t8ImUBPtEN1sym9OVz0pRGtBAhjaF5DYVpLUm0D7+cyuA4G/yKmjN7AEtvxDsr7t9aZaGII16p1WX5KU+A9o8aldRJPZEqCKTNY/+mYpHOEj9p1L8PE7AymXMlPGhfL1xpwrApaO9gk9eIQkO2mbe9xE8HZKeJ/WPLDhoVI/yOn1Ulof2k2QvvrqHc78e28ieqk5lcmBn1apZe4IMVBfhK9Gtc4Wtmaga1Dya2YP7j5qc0I0vFXERI9Lr2wMHDHRy85nS5qzLFBMSc+OYVW1s0xn2u3XMeldyWcWWrCbOsY/W/V7Ojv0pwEAVfUTCjxEExjerGj9r78LZA9ICy+0j3+hTzn1D+b3LZkKPl1AXq4MI320YAo4M4nHtvpaaUsI/+6g0YBq+zpga8AoESyIyCtouY8nnTBraEcHBmoUK0ly1VBrBKMUB/sGe8xjOMmfxNwHSNEY6CqhGtf3UTXLq7NWuIHkKVmjIYtVbbsc0YWiovVT2hHsfLGVG5JYrTH/+vN7fDVq7VwMQnVQBXtzBmmntwmdSpeWU0w1x8mLWgMiGbLQxDJn2ee3p4C5ub0NPgCXsMbxEbsjC2eeRUMaKcyJS0LuSPkDlzk5Z9P05HkemaPfBNvnV1JwQ9kaT7Otvj7Ynr1OoXFZTgokPHw== cardno:24_483_552"
        ];
      };

      hjem.users.sana = {
        enable = true;
        packages = with pkgs; [
          vim
        ];

        files = {
          ".config/git/config".text = gitConfigText;
          ".zshrc".text = zshConfigText;
          ".vimrc".text = vimrc;
        };
      };
    })

    (lib.mkIf (cfg.enable && config.site.profiles.graphics.enable) {
      hjem.users.sana = {
        packages = with pkgs; [
          librewolf
          mpv
          kitty
          imv
          mupdf
          dmenu
          feh
          pulseaudio
          scrot
          xclip
          bibata-cursors
        ];

        files = {
          ".config/mimeapps.list".text = xdgMimeAppsText;
          ".xinitrc".text = xinitrcText;
        };
      };

      environment.systemPackages = [
        (packages.dwm { inherit pkgs lib; colorscheme = if c.enable then c.colors else null; })
        (packages.slstatus { inherit pkgs lib; })
      ];

      environment.sessionVariables = {
        XCURSOR_SIZE = "24";
        XCURSOR_THEME = "Bibata-Original-Classic";
      };
    })

    (lib.mkIf (cfg.enable && config.site.profiles.laptop.enable) {
      hjem.users.sana = {
        packages = with pkgs; [
          brightnessctl
        ];
      };
    })
  ];
}
