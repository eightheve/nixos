{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.site.users.sana;
  agent = cfg.agent;
  bash = "${pkgs.bashInteractive}/bin/bash";
in
{
  options.site.users.sana.agent = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable the sandboxed agent user and helper commands";
    };

    userName = lib.mkOption {
      type = lib.types.str;
      default = "agent";
      description = "Unprivileged user that coding agents run as";
    };
  };

  config = lib.mkIf (cfg.enable && agent.enable) {
    users.users.${agent.userName} = {
      isNormalUser = true;
      createHome = true;
      shell = pkgs.bashInteractive;
    };

    security.doas.extraRules = lib.mkAfter [
      {
        users = [ "sana" ];
        runAs = agent.userName;
        noPass = true;
        setEnv = [
          "-SSH_AUTH_SOCK"
          "LANG"
          "PATH"
        ];
      }
    ];

    programs.ssh.knownHosts."github.com".publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

    hjem.users.${agent.userName} = {
      enable = true;
      packages = with pkgs; [
        git
        gh
        (writeShellScriptBin "clean-temp" ''
          cd "$HOME"
          exec find /tmp /var/tmp -mindepth 1 -maxdepth 1 -user "$(id -un)" -exec rm -rf {} \;
        '')
      ];

      files.".config/git/config".text = ''
        [user]
          name = doppelsana
          email = agent@doppel.moe
        [init]
          defaultBranch = main
        [safe]
          directory = *
      '';
    };

    hjem.users.sana.packages = [
      pkgs.acl
      (pkgs.writeShellScriptBin "agent" ''
        export PATH="/etc/profiles/per-user/${agent.userName}/bin:$PATH"
        if [ "$#" -eq 0 ]; then
          exec /run/wrappers/bin/doas -u ${agent.userName} ${bash} -l
        fi
        exec /run/wrappers/bin/doas -u ${agent.userName} -- "$@"
      '')
      (pkgs.writeShellScriptBin "agent-share" ''
        set -eu
        if [ "$#" -eq 0 ]; then
          echo "usage: agent-share <dir>..." >&2
          exit 2
        fi
        for d in "$@"; do
          setfacl -R -m u:${agent.userName}:rwX,u:sana:rwX -- "$d"
          find "$d" -type d -exec setfacl -m d:u:${agent.userName}:rwX,d:u:sana:rwX {} +
        done
      '')
    ];
  };
}
