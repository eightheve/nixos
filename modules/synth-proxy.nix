{
  config,
  lib,
  ...
}:
let
  cfg = config.site.modules.synthProxy;
  topology = config.site.topology;
  me = config.site.modules.networking.hostName;

  wgServerIp =
    let
      host = topology.${me} or null;
      ifaces = if host != null && host.wireguard != null then host.wireguard.interfaces else { };
      server = lib.findFirst (i: i.isServer) null (lib.attrValues ifaces);
    in
    if server != null then server.ip else null;

  keyInclude = "/run/llm-proxy/auth.conf";
in
{
  options.site.modules.synthProxy = {
    enable = lib.mkEnableOption "unauthenticated llm api proxy";

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 7777;
    };

    upstream = lib.mkOption {
      type = lib.types.str;
      default = "https://api.synthetic.new/";
    };

    environmentFilePath = lib.mkOption {
      type = lib.types.str;
      default = "/etc/llm-proxy.env";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        site.modules.synthProxy.listenAddress = lib.mkIf (wgServerIp != null) (lib.mkDefault wgServerIp);
        services.nginx = {
          enable = true;
          appendHttpConfig = ''
            map $http_upgrade $connection_upgrade {
              default upgrade;
              '''      close;
            }
          '';

          virtualHosts.llm-proxy = {
            listen = [
              {
                addr = cfg.listenAddress;
                port = cfg.port;
              }
            ];
            extraConfig = ''
              client_max_body_size 0;
            '';
            locations."/" = {
              proxyPass = cfg.upstream;
              recommendedProxySettings = false;
              extraConfig = ''
                include ${keyInclude};
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection $connection_upgrade;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_buffering off;
                proxy_cache off;
                proxy_connect_timeout 60s;
                proxy_read_timeout 3600s;
                proxy_send_timeout 3600s;
                proxy_ssl_server_name on;
              '';
            };
          };
        };

        systemd.services.llm-proxy-key = {
          description = "LLM proxy Authorization include for nginx";
          before = [ "nginx.service" ];
          requiredBy = [ "nginx.service" ];
          serviceConfig = {
            EnvironmentFile = cfg.environmentFilePath;
            Type = "oneshot";
            RemainAfterExit = true;
            Group = "nginx";
            RuntimeDirectory = "llm-proxy";
            RuntimeDirectoryMode = "0750";
            UMask = "0027";
            ExecStartPost = "systemctl try-restart nginx.service";
          };
          script = ''
            printf 'proxy_set_header Authorization "Bearer %s";\n' "$SYNTHETIC_API_KEY" > ${keyInclude}
          '';
        };

        networking.firewall.interfaces.wg0.allowedTCPPorts = [ cfg.port ];
      }
    ]
  );
}
