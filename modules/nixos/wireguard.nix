{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myModules.wireguard;

  peerSubmodule = lib.types.submodule {
    options = {
      publicKey = lib.mkOption {
        type = lib.types.str;
        description = "Peer's public key";
      };
      allowedIPs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "IP ranges this peer can use";
      };
      endpoint = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Endpoint address:port";
      };
      persistentKeepalive = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Keepalive interval in seconds";
      };
    };
  };
in {
  options.myModules.wireguard = {
    enable = lib.mkEnableOption "WireGuard VPN";

    role = lib.mkOption {
      type = lib.types.enum ["server" "client"];
      description = "Whether this host is a server or client";
    };

    ip = lib.mkOption {
      type = lib.types.str;
      description = "WireGuard interface IP with CIDR (e.g., 10.100.0.1/24)";
    };

    listenPort = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default =
        if cfg.role == "server"
        then 51820
        else null;
      description = "Port to listen on (server only)";
    };

    privateKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/wireguard/privatekey";
      description = "Path to private key file";
    };

    peers = lib.mkOption {
      type = lib.types.listOf peerSubmodule;
      default = [];
      description = "List of WireGuard peers";
    };

    server = {
      externalInterface = lib.mkOption {
        type = lib.types.str;
        default = "enp1s0";
        description = "External network interface for NAT";
      };

      natForwardPorts = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Forward all traffic except SSH to first peer";
      };

      sshPort = lib.mkOption {
        type = lib.types.int;
        default = 2222;
        description = "SSH port to exclude from forwarding";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.wireguard-tools];

    networking.wireguard.interfaces.wg0 = {
      ips = [cfg.ip];
      privateKeyFile = cfg.privateKeyFile;
      inherit (cfg) listenPort peers;
    };

    networking.enableIPv6 = lib.mkIf (cfg.role == "server") true;

    boot.kernel.sysctl = lib.mkIf (cfg.role == "server") {
      "net.ipv4.ip_forward" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };

    networking.nat = lib.mkIf (cfg.role == "server") {
      enable = true;
      externalInterface = cfg.server.externalInterface;
      internalInterfaces = ["wg0"];
    };

    networking.firewall.extraCommands = lib.mkIf (cfg.role == "server" && cfg.server.natForwardPorts) ''
      iptables -t nat -F PREROUTING
      iptables -t nat -A PREROUTING -i ${cfg.server.externalInterface} -p tcp ! --dport ${toString cfg.server.sshPort} -j DNAT --to-destination ${lib.removeSuffix "/32" (lib.head ((lib.head cfg.peers).allowedIPs))}
      iptables -t nat -A PREROUTING -i ${cfg.server.externalInterface} -p udp ! --dport ${toString cfg.server.sshPort} -j DNAT --to-destination ${lib.removeSuffix "/32" (lib.head ((lib.head cfg.peers).allowedIPs))}
      iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE
    '';
  };
}
