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

  interfaceSubmodule = lib.types.submodule {
    options = {
      role = lib.mkOption {
        type = lib.types.enum ["server" "client"];
        description = "Whether this interface is a server or client";
      };

      ip = lib.mkOption {
        type = lib.types.str;
        description = "WireGuard interface IP with CIDR (e.g., 10.100.0.1/24)";
      };

      listenPort = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Port to listen on";
      };

      privateKeyFile = lib.mkOption {
        type = lib.types.str;
        description = "Path to private key file";
      };

      peers = lib.mkOption {
        type = lib.types.listOf peerSubmodule;
        default = [];
        description = "List of WireGuard peers";
      };

      postSetup = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Commands to run after interface is up";
      };

      preShutdown = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Commands to run before interface goes down";
      };
    };
  };

  serverSubmodule = lib.types.submodule {
    options = {
      externalInterface = lib.mkOption {
        type = lib.types.str;
        default = "enp1s0";
        description = "External network interface for NAT";
      };

      interfaces = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "WireGuard interfaces to NAT for";
      };

      natForwardPorts = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Forward all traffic except SSH to first peer of first interface";
      };

      sshPort = lib.mkOption {
        type = lib.types.int;
        default = 2222;
        description = "SSH port to exclude from forwarding";
      };
    };
  };
in {
  options.myModules.wireguard = {
    enable = lib.mkEnableOption "WireGuard VPN";

    interfaces = lib.mkOption {
      type = lib.types.attrsOf interfaceSubmodule;
      default = {};
      description = "WireGuard interfaces configuration";
    };

    server = lib.mkOption {
      type = lib.types.nullOr serverSubmodule;
      default = null;
      description = "Server-specific configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.wireguard-tools];

    networking.wireguard.interfaces =
      lib.mapAttrs (name: ifaceCfg: {
        ips = [ifaceCfg.ip];
        privateKeyFile = ifaceCfg.privateKeyFile;
        listenPort = ifaceCfg.listenPort;
        peers = ifaceCfg.peers;
        inherit (ifaceCfg) postSetup preShutdown;
      })
      cfg.interfaces;

    networking.enableIPv6 = lib.mkIf (cfg.server != null) true;

    boot.kernel.sysctl = lib.mkIf (cfg.server != null) {
      "net.ipv4.ip_forward" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };

    networking.nat = lib.mkIf (cfg.server != null) {
      enable = true;
      externalInterface = cfg.server.externalInterface;
      internalInterfaces = cfg.server.interfaces;
    };

    networking.firewall.extraCommands = lib.mkIf (cfg.server != null && cfg.server.natForwardPorts) (let
      firstInterface = lib.head (lib.attrNames cfg.interfaces);
      firstPeer = lib.head cfg.interfaces.${firstInterface}.peers;
      targetIP = lib.removeSuffix "/32" (lib.head firstPeer.allowedIPs);
    in ''
      iptables -t nat -F PREROUTING
      iptables -t nat -A PREROUTING -i ${cfg.server.externalInterface} -p tcp ! --dport ${toString cfg.server.sshPort} -j DNAT --to-destination ${targetIP}
      iptables -t nat -A PREROUTING -i ${cfg.server.externalInterface} -p udp ! --dport 51820 -j DNAT --to-destination ${targetIP}
      iptables -t nat -A POSTROUTING -o ${firstInterface} -j MASQUERADE
    '');
  };
}
