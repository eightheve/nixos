{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.site.modules.maddy;
  stsCfg = cfg.mtaSts;

  stsPolicyDir = pkgs.runCommand "mta-sts-policy" {} ''
    mkdir -p $out/.well-known
    cat > $out/.well-known/mta-sts.txt <<EOF
    version: STSv1
    mode: ${stsCfg.mode}
    mx: ${cfg.hostname}
    max_age: ${toString stsCfg.maxAge}
    EOF
  '';
in {
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
        type = lib.types.enum ["testing" "enforce" "none"];
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
        localDomains = [cfg.primaryDomain];
        openFirewall = true;
        tls = {
          loader = "file";
          certificates = [
            {
              certPath = "/var/lib/acme/${cfg.hostname}/fullchain.pem";
              keyPath = "/var/lib/acme/${cfg.hostname}/key.pem";
            }
          ];
        };
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

      users.users.maddy.extraGroups = ["nginx"];

      systemd.services.maddy = {
        after = ["acme-${cfg.hostname}.service"];
        wants = ["acme-${cfg.hostname}.service"];
      };

      networking.firewall.allowedTCPPorts = [80 443];
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
