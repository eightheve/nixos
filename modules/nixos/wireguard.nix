{
  config,
  lib,
  ...
}: let
  cfg = config.site.modules.wireguard;
  wireguardDefs = import ./wireguard-defs.nix;
  currentHost = wireguardDefs.hosts.${config.networking.hostName} or null;
  allPeers = lib.filterAttrs (n: v: n != config.networking.hostName) wireguardDefs.hosts;
  serverPeer = lib.findSingle (v: v.isServer) null null (lib.attrValues wireguardDefs.hosts);
in {
  options.site.modules.wireguard = {
    enable = lib.mkEnableOption "wireguard VPN";

    privateKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/wireguard/privatekey";
      description = "Path to the private key file";
    };

    serverEndpoint = lib.mkOption {
      type = lib.types.str;
      default = "5.161.238.34:51820";
      description = "Endpoint for the WireGuard server (client-only)";
    };

    persistentKeepalive = lib.mkOption {
      type = lib.types.int;
      default = 25;
      description = "Persistent keepalive interval in seconds (client-only)";
    };
  };

  config = lib.mkIf (cfg.enable && currentHost != null) {
    networking.wireguard.interfaces.wg0 = {
      ips = ["${currentHost.ip}/24"];
      privateKeyFile = cfg.privateKeyFile;
    }
    // lib.optionalAttrs currentHost.isServer {
      listenPort = currentHost.listenPort;
      peers = lib.mapAttrsToList (name: peer: {
        publicKey = peer.publicKey;
        allowedIPs = ["${peer.ip}/32"];
      }) allPeers;
    }
    // lib.optionalAttrs (!currentHost.isServer) {
      peers = [
        {
          publicKey = serverPeer.publicKey;
          allowedIPs = ["${wireguardDefs.network}"];
          endpoint = cfg.serverEndpoint;
          persistentKeepalive = cfg.persistentKeepalive;
        }
      ];
    };

    # Configure firewall for servers
    networking.firewall = lib.mkIf currentHost.isServer {
      allowedUDPPorts = [currentHost.listenPort];
    };

    # Enable IP forwarding for servers
    boot.kernel.sysctl = lib.mkIf currentHost.isServer {
      "net.ipv4.ip_forward" = true;
    };
  };
}
