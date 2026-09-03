{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.site.modules.maddy;
  stsCfg = cfg.mtaSts;

  stsPolicyDir = pkgs.runCommand "mta-sts-policy" { } ''
    mkdir -p $out/.well-known
    cat > $out/.well-known/mta-sts.txt <<EOF
    version: STSv1
    mode: ${stsCfg.mode}
    mx: ${cfg.hostname}
    max_age: ${toString stsCfg.maxAge}
    EOF
  '';
in
{
  options.site.modules.maddy = {
    enable = lib.mkEnableOption "maddy mail server";

    hostname = lib.mkOption {
      type = lib.types.str;
      default = "mail.wokestory.org";
      description = "FQDN maddy uses in HELO/EHLO. Must match the PTR record on the sending IP for deliverability.";
    };

    primaryDomain = lib.mkOption {
      type = lib.types.str;
      default = "wokestory.org";
      description = "Primary mail domain. Mailboxes are addressed as user@<primaryDomain>.";
    };

    mtaSts = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Serve an MTA-STS policy at https://mta-sts.<primaryDomain>/.well-known/mta-sts.txt.
          Requires corresponding _mta-sts and _smtp._tls TXT records in DNS.
        '';
      };

      mode = lib.mkOption {
        type = lib.types.enum [
          "testing"
          "enforce"
          "none"
        ];
        default = "enforce";
        description = ''
          MTA-STS policy mode.
          - testing: send TLSRPT reports but allow non-TLS delivery (safe for new setups)
          - enforce: refuse delivery if TLS cannot be established (safe once TLS is confirmed working)
          - none: policy disabled
        '';
      };

      maxAge = lib.mkOption {
        type = lib.types.int;
        default = 604800;
        description = "Policy cache lifetime in seconds. Default is 1 week.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.maddy = {
        enable = true;
        inherit (cfg) hostname primaryDomain;
        localDomains = [ cfg.primaryDomain ];
        # Do not use the module's openFirewall: it opens legacy plaintext IMAP
        # 143. Open only smtp/submission/imaps explicitly below.
        openFirewall = false;
        tls = {
          loader = "file";
          certificates = [
            {
              certPath = "/var/lib/acme/${cfg.hostname}/fullchain.pem";
              keyPath = "/var/lib/acme/${cfg.hostname}/key.pem";
            }
          ];
        };
        config = ''
          auth.pass_table local_authdb {
            table sql_table {
              driver sqlite3
              dsn credentials.db
              table_name passwords
            }
          }

          storage.imapsql local_mailboxes {
            driver sqlite3
            dsn imapsql.db
          }

          table.chain local_rewrites {
            optional_step regexp "(.+)\+(.+)@(.+)" "$1@$3"
            optional_step static {
              entry postmaster postmaster@$(primary_domain)
            }
            optional_step file /etc/maddy/aliases
          }

          msgpipeline local_routing {
            destination postmaster $(local_domains) {
              modify {
                replace_rcpt &local_rewrites
              }
              deliver_to &local_mailboxes
            }
            default_destination {
              reject 550 5.1.1 "User doesn't exist"
            }
          }

          smtp tcp://0.0.0.0:25 {
            limits {
              all rate 20 1s
              all concurrency 10
            }
            dmarc yes
            check {
              require_mx_record
              dkim
              spf
            }
            source $(local_domains) {
              reject 501 5.1.8 "Use Submission for outgoing SMTP"
            }
            default_source {
              destination postmaster $(local_domains) {
                deliver_to &local_routing
              }
              default_destination {
                reject 550 5.1.1 "User doesn't exist"
              }
            }
          }

          submission tcp://0.0.0.0:587 {
            limits {
              all rate 50 1s
            }
            auth &local_authdb
            source $(local_domains) {
              check {
                authorize_sender {
                  prepare_email &local_rewrites
                  user_to_email identity
                }
              }
              destination postmaster $(local_domains) {
                deliver_to &local_routing
              }
              default_destination {
                modify {
                  dkim $(primary_domain) $(local_domains) default
                }
                deliver_to &remote_queue
              }
            }
            default_source {
              reject 501 5.1.8 "Non-local sender domain"
            }
          }

          smtp tcp://127.0.0.1:5879 {
            limits {
              all rate 50 1s
            }
            source $(local_domains) {
              destination postmaster $(local_domains) {
                deliver_to &local_routing
              }
              default_destination {
                modify {
                  dkim $(primary_domain) $(local_domains) default
                }
                deliver_to &remote_queue
              }
            }
            default_source {
              reject 501 5.1.8 "Non-local sender domain"
            }
          }

          target.remote outbound_delivery {
            limits {
              destination rate 20 1s
              destination concurrency 10
            }
            mx_auth {
              dane
              mtasts {
                cache fs
                fs_dir mtasts_cache/
              }
              local_policy {
                min_tls_level encrypted
                min_mx_level none
              }
            }
          }

          target.queue remote_queue {
            target &outbound_delivery
            autogenerated_msg_domain $(primary_domain)
            bounce {
              destination postmaster $(local_domains) {
                deliver_to &local_routing
              }
              default_destination {
                reject 550 5.0.0 "Refusing to send DSNs to non-local addresses"
              }
            }
          }

          imap tls://0.0.0.0:993 {
            auth &local_authdb
            storage &local_mailboxes
          }
        '';
      };

      services.nginx = {
        enable = true;
        virtualHosts.${cfg.hostname} = {
          enableACME = true;
          locations."/".return = "444";
        };
      };

      security.acme.certs.${cfg.hostname} = {
        group = "nginx";
        postRun = "systemctl reload nginx.service; systemctl restart maddy.service";
      };

      users.users.maddy.extraGroups = [ "nginx" ];

      systemd.services.maddy = {
        after = [ "acme-${cfg.hostname}.service" ];
        wants = [ "acme-${cfg.hostname}.service" ];
        serviceConfig = {
          # Hardening. Port binding uses systemd-granted capabilities from the
          # package unit, which NoNewPrivileges does not block.
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          NoNewPrivileges = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          # Mail state under /var/lib/maddy is auto-writable via the module's
          # StateDirectory; ACME certs and /etc/maddy aliases stay readable.
          ReadOnlyPaths = [
            "/var/lib/acme"
            "/etc/maddy"
          ];
        };
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
        25
        587
        993
      ];
    })

    (lib.mkIf (cfg.enable && stsCfg.enable) {
      services.nginx.virtualHosts."mta-sts.${cfg.primaryDomain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/.well-known/mta-sts.txt" = {
          root = "${stsPolicyDir}";
          tryFiles = "/mta-sts.txt =404";
          extraConfig = "default_type text/plain;";
        };
      };
    })
  ];
}
