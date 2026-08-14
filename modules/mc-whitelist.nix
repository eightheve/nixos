{
  config,
  lib,
  pkgs-unstable,
  inputs,
  ...
}:
let
  cfg = config.site.modules.mcWhitelist;
  resourcePack = "${inputs.mc-whitelist}/Matcha_Flavoured_1_03.zip";
in
{
  options.site.modules.mcWhitelist = {
    enable = lib.mkEnableOption "Minecraft (Paper) server with self-service whitelist site";

    nginx = {
      enable = lib.mkEnableOption "nginx vhost";
      upstream = lib.mkOption {
        type = lib.types.str;
        default = "http://10.100.0.2:25566";
      };
      domainName = lib.mkOption {
        type = lib.types.str;
        default = "mc.doppel.moe";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.mc-whitelist = {
        enable = true;
        serverPackage = pkgs-unstable.minecraftServers.vanilla;
      };
    })

    (lib.mkIf cfg.nginx.enable {
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        virtualHosts."${cfg.nginx.domainName}" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = cfg.nginx.upstream;
          };
          # Static resource pack download; referenced by resource-pack in
          # server.properties on SAOTOME.
          locations."= /resourcepack.zip" = {
            alias = resourcePack;
            extraConfig = ''
              default_type application/zip;
              add_header Cache-Control "public, max-age=86400";
            '';
          };
        };
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
    })
  ];
}
