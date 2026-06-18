{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.site.users.benjamin;

  gitConfigText = ''
    [user]
      name = ikupoku
      email = benjamin.z.zhang@gmail.com
  '';

  zshConfigText = ''
    setopt HIST_IGNORE_DUPS
    bindkey -e 
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    EDITOR=nano
  '';
in {
  options.site.users.benjamin = {
    enable = lib.mkEnableOption "benjamin user";
  };

  config = lib.mkIf cfg.enable {
    users.users.benjamin = {
      isNormalUser = true;
      createHome = true;
      homeMode = "711";
      description = "Benjamin Zhang";
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKkIafdFkbx/nAa2obU7EkJxsYsEYbnmW0MH0fJwbB4V benjamin.z.zhang@gmail.com"
      ];
    };
     
    hjem.users.benjamin.files = {
      ".config/git/config".text = gitConfigText;
      ".zshrc".text = zshConfigText;
    };

    systemd.tmpfiles.rules = [
      "d /srv/benjamin/www 0755 benjamin users - -"
    ];

    networking.firewall.allowedTCPPorts = [ 3030 ];
  
    services.nginx = {
      enable = true;
      virtualHosts.localhost = {
        listen = [{addr = "0.0.0.0"; port = 3030;}];
        root = "/srv/benjamin/www";
        locations."/" = {
          tryFiles = "$uri $uri/ =404";
        };
      };
    };
  };
}
