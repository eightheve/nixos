# Shared helpers for the site NixOS modules.
#
# Exposed to modules as `site.lib` via `specialArgs` in flake.nix.
{ lib }:
{
  # Build the standard reverse-proxy nginx vhost used across site modules:
  # TLS via ACME, proxy to an upstream, and the 80/443 firewall rule.
  #
  # Args:
  #   domain: vhost name, e.g. "navi.doppel.moe" (required)
  #   upstream: proxyPass target, e.g. "http://127.0.0.1:4533" (required)
  #   proxyWebsockets: enable websocket proxying (default: false)
  #   enableACME: request a certificate via ACME (default: true)
  #   extraLocations: extra nginx locations merged into the vhost (default: {})
  #   recommendedSettings: set recommendedProxySettings and recommendedTlsSettings
  #     (default: true)
  #   openFirewall: open TCP ports 80 and 443 (default: true)
  mkProxyVhost =
    {
      domain,
      upstream,
      proxyWebsockets ? false,
      enableACME ? true,
      extraLocations ? { },
      recommendedSettings ? true,
      openFirewall ? true,
    }:
    {
      services.nginx = {
        enable = true;
        virtualHosts.${domain} = {
          forceSSL = true;
          inherit enableACME;
          locations = {
            "/" = {
              proxyPass = upstream;
            }
            // lib.optionalAttrs proxyWebsockets {
              proxyWebsockets = true;
            };
          }
          // extraLocations;
        };
      }
      // lib.optionalAttrs recommendedSettings {
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
      };
    }
    // lib.optionalAttrs openFirewall {
      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
    };
}
