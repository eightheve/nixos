{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.site.modules.katydid;
  package = inputs.katydid.packages.${pkgs.stdenv.hostPlatform.system}.default;

  credentialsScript = pkgs.writeShellScript "katydid-credentials" ''
    set -euo pipefail

    key_file=/var/lib/katydid/api-key
    install -d -m 0755 /var/lib/katydid
    install -d -m 0755 /var/lib/slskd
    if [ ! -s "$key_file" ]; then
      umask 077
      ${pkgs.openssl}/bin/openssl rand -hex 32 > "$key_file"
    fi
    key=$(cat "$key_file")

    tmp=$(mktemp /var/lib/slskd/.env.katydid.XXXXXX)
    {
      cat ${lib.escapeShellArg cfg.settings.slskdEnvFile} 2>/dev/null || true
      printf 'SLSKD_API_KEY=role=readwrite;cidr=127.0.0.1/32,::1/128;%s\n' "$key"
    } > "$tmp"
    chown slskd:slskd "$tmp"
    chmod 0440 "$tmp"
    mv -f "$tmp" ${lib.escapeShellArg cfg.settings.generatedSlskdEnvFile}

    tmp=$(mktemp /var/lib/katydid/fetchd.env.XXXXXX)
    printf 'KATYFETCHD_API_KEY=%s\n' "$key" > "$tmp"
    chown slskd:katydid "$tmp"
    chmod 0440 "$tmp"
    mv -f "$tmp" /var/lib/katydid/fetchd.env
  '';
in
{
  options.site.modules.katydid = {
    enable = lib.mkEnableOption "katydid music library daemon and soulseek fetcher";

    settings = {
      library = lib.mkOption {
        type = lib.types.str;
        default = "/srv/data/katydid";
      };

      slskdEnvFile = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/slskd/.env";
        description = "manually managed slskd secrets; prepended to the generated env file";
      };

      generatedSlskdEnvFile = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/slskd/.env.katydid";
      };

      slskdUrl = lib.mkOption {
        type = lib.types.str;
        default = "http://127.0.0.1:5030";
      };

      slskdDownloads = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/slskd/downloads";
      };

      discord.enable = lib.mkEnableOption "enable discord integrations";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = config.services.slskd.enable;
            message = "site.modules.katydid requires site.modules.slskd";
          }
        ];

        users.groups.katydid = { };

        users.users.katydid = {
          isSystemUser = true;
          group = "katydid";
          home = "/var/lib/katydid";
          createHome = true;
          homeMode = "750";
          extraGroups = [
            "slskd"
          ];
        };

        systemd.tmpfiles.rules = [
          "d ${cfg.settings.library} 0755 katydid katydid - -"
        ];

        systemd.services.katydid-credentials = {
          description = "generate the shared slskd/katydid api credential";
          before = [
            "slskd.service"
            "katyd.service"
            "katy-fetchd.service"
          ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = credentialsScript;
          };
        };

        systemd.services.katyd = {
          description = "katydid music library daemon";
          wantedBy = [ "multi-user.target" ];
          after = [ "local-fs.target" ];
          environment.KATYDID_MB_CACHE = "/var/lib/katydid/mb";
          serviceConfig = {
            User = "katydid";
            Group = "katydid";
            UMask = "0022";
            EnvironmentFile = "/var/lib/katydid/katyd.env";
            ExecStart = "${package}/bin/katyd -library ${cfg.settings.library} -socket /run/katyd/katyd.sock";
            RuntimeDirectory = "katyd";
            RuntimeDirectoryMode = "0755";
            Restart = "on-failure";
          };
        };

        systemd.services.katy-fetchd = {
          description = "katydid soulseek fetcher";
          wantedBy = [ "multi-user.target" ];
          requires = [ "katydid-credentials.service" ];
          after = [
            "katydid-credentials.service"
            "katyd.service"
            "slskd.service"
          ];
          serviceConfig = {
            User = "katydid";
            Group = "katydid";
            UMask = "0027";
            EnvironmentFile = "/var/lib/katydid/fetchd.env";
            ExecStart = "${package}/bin/katy-fetchd -socket /run/katy-fetchd/fetchd.sock -katyd /run/katyd/katyd.sock -slskd ${cfg.settings.slskdUrl} -downloads ${cfg.settings.slskdDownloads} -state /var/lib/katydid/state.json";
            RuntimeDirectory = "katy-fetchd";
            RuntimeDirectoryMode = "0755";
            Restart = "on-failure";
          };
        };

        systemd.services.katy-discordd = lib.mkIf cfg.settings.discord.enable {
          description = "katydid discord integration";
          wantedBy = [ "multi-user.target" ];
          requires = [
            "katy-fetchd.service"
            "katyd.service"
          ];
          serviceConfig = {
            User = "katydid";
            Group = "katydid";
            UMask = "0027";
            EnvironmentFile = "/var/lib/katydid/discord.env";
            ExecStart = "${package}/bin/katy-discordd -fetchd-socket /run/katy-fetchd/fetchd.sock -katyd-socket /run/katyd/katyd.sock";
            Restart = "on-failure";
          };
        };

        environment.systemPackages = [ package ];
      }

      (lib.mkIf config.services.slskd.enable {
        systemd.services.slskd = {
          requires = [ "katydid-credentials.service" ];
          after = [ "katydid-credentials.service" ];
          serviceConfig.UMask = lib.mkForce "0002";
        };
      })
    ]
  );
}
