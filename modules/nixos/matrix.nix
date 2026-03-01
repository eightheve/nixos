{
  config,
  lib,
  ...
}: let
  cfg = config.myModules.matrix;
in {
  options.myModules.matrix = {
    synapse = {
      enable = lib.mkEnableOption "synapse web server";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.synapse.enable {
      networking.firewall.allowedTCPPorts = [80 443 8448];

      services = {
        postgresql.enable = true;

        matrix-synapse = {
          enable = true;
          extraConfigFiles = "/var/lib/matrix-synapse";
          settings = {
            server_name = "doppel.moe";
            public_baseurl = "https://matrix.doppel.moe/";
            enable_registration = true;
            tls_certificate_path = "/var/lib/acme/matrix.doppel.moe/fullchain.pem";
            tls_private_key_path = "/var/lib/acme/matrix.doppel.moe/key.pem";
            listeners = [
              {
                bind_address = "";
                port = 8448;
                resources = [
                  {
                    compress = true;
                    names = ["client" "webclient"];
                  }
                  {
                    compress = false;
                    names = ["federation"];
                  }
                ];
                tls = true;
                type = "http";
                x_forwarded = false;
              }
              {
                # client
                bind_address = "127.0.0.1";
                port = 8008;
                resources = [
                  {
                    compress = true;
                    names = ["client" "webclient"];
                  }
                ];
                tls = false;
                type = "http";
                x_forwarded = true;
              }
            ];
          };
        };
        nginx = {
          enable = true;
          virtualHosts."matrix.doppel.moe" = {
            forceSSL = true;
            enableACME = true;
            locations."/" = {
              proxyPass = "http://127.0.0.1:8008";
            };
          };
        };
      };

      security.acme.certs = {
        "matrix.doppel.moe" = {
          group = "matrix-synapse";
          allowKeysForGroup = true;
          postRun = "systemctl reload nginx.service; systemctl restart matrix-synapse.service";
        };
      };
    })
  ];
}
