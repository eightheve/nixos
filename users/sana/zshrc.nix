pkgs: ''
  autoload -U colors && colors

  HISTSIZE=10000
  SAVEHIST=10000
  setopt SHARE_HISTORY
  setopt HIST_IGNORE_DUPS
  unsetopt BEEP

  bindkey -e

  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  EDITOR=vim

  if [ -n "$IN_NIX_SHELL" ]; then
    PROMPT="%{$fg[cyan]%}(nix)%{$reset_color%} $PROMPT"
  fi

  alias ssh="gpg-connect-agent updatestartuptty /bye >/dev/null && ssh"
  alias mdv='${pkgs.glow}/bin/glow -pw $(tput cols)'
''
