{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myModules.matrix;

  serverConfig."m.server" = "matrix.doppel.moe:8448";
  clientConfig."m.homeserver".base_url = "https://matrix.doppel.moe:8448";
  supportConfig = {
    contacts = [
      {
        matrix_id = "@sana:doppel.moe";
        email_address = "sana@doppel.moe";
        role = "m.role.admin";
      }
    ];
  };
  mkWellKnown = data: ''
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';
in {
  options.myModules.matrix = {
    synapse = {
      enable = lib.mkEnableOption "synapse web server";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.synapse.enable {
      nixpkgs.config.permittedInsecurePackages = [
        "olm-3.2.16"
      ];

      networking.firewall.allowedTCPPorts = [80 443 8448 8008];

      services = {
        postgresql.enable = true;

        matrix-synapse = {
          enable = true;
          extraConfigFiles = ["/var/lib/matrix-synapse/secret.yaml"];
          settings = {
            server_name = "doppel.moe";
            public_baseurl = "https://matrix.doppel.moe:8448";
            tls_certificate_path = "/var/lib/acme/matrix.doppel.moe/fullchain.pem";
            tls_private_key_path = "/var/lib/acme/matrix.doppel.moe/key.pem";
            app_service_config_files = [ "/var/lib/matrix-synapse/discord-registration.yaml" ];
            listeners = [
              {
                bind_addresses = [""];
                port = 8448;
                resources = [
                  {
                    compress = true;
                    names = ["client"];
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
                bind_addresses = ["0.0.0.0"];
                port = 8008;
                resources = [
                  {
                    compress = true;
                    names = ["client"];
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
          virtualHosts."doppel.moe" = {
            enableACME = true;
            forceSSL = true;
            locations."/.well-known/matrix/server".extraConfig = mkWellKnown serverConfig;
            locations."/.well-known/matrix/support".extraConfig = mkWellKnown supportConfig;
            locations."/.well-known/matrix/client".extraConfig = mkWellKnown clientConfig;
          };
          virtualHosts."mautrix-media.doppel.moe" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
              proxyPass = "http://127.0.0.1:29334";
            };
          };
        };
      };

      security.acme.certs = {
        "matrix.doppel.moe" = {
          group = "nginx";
          postRun = "systemctl reload nginx.service; systemctl restart matrix-synapse.service";
        };
      };
      users.users.matrix-synapse.extraGroups = ["nginx"];
    
     
      services.mautrix-discord = {
        enable = true;
        registerToSynapse = true;
        settings = {
          homeserver = {
            address = "https://matrix.doppel.moe";
            domain = "doppel.moe";
          };
          appservice = {
            id = "_mautrix_discord";
            database = {
              type = "postgres";
              uri = "postgres://mautrix-discord:password@127.0.0.1/mautrix-discord?sslmode=disable";
            };
            bot = {
              username = "_mautrix_bridge";
              displayname = "Mautrix Bridge";
            };
          };
          bridge = {
            public_address = "https://mautrix-media.doppel.moe";
            direct_media = {
              enabled = true;
              server_name = "mautrix-media.doppel.moe";
            };
            permissions = {
              "*" = "relay";
              "@root:doppel.moe" = "admin";
            };
          };
        };
      };
    })
  ];
}
