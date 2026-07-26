{
  config,
  lib,
  ...
}: let
  cfg = config.site.modules.networking;
  topology = config.site.topology;
  currentHostName = cfg.hostName;
  currentHost = topology.${currentHostName} or null;

  hostsOnNetwork = network:
    lib.filterAttrs (_: host:
      host.wireguard != null
      && lib.any (iface: iface.network == network)
        (lib.attrValues host.wireguard.interfaces)
    ) topology;

  findServerOnNetwork = network: let
    candidates = hostsOnNetwork network;
  in
    lib.findFirst (entry: let
      host = entry.value;
    in
      lib.any (iface: iface.network == network && iface.isServer)
      (lib.attrValues host.wireguard.interfaces)
    ) null (lib.mapAttrsToList lib.nameValuePair candidates);

  ifaceForNetwork = host: network:
    lib.findFirst (iface: iface.network == network) null
    (lib.attrValues host.wireguard.interfaces);
in {
  options.site.modules.networking = {
    enable = lib.mkEnableOption "networking";

    hostName = lib.mkOption {
      type = lib.types.str;
      default = "nixos";
    };

    wireguardPrivateKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/wireguard/privatekey";
    };
  };

  config = lib.mkIf (cfg.enable && currentHost != null) {
    networking = {
      hostName = currentHostName;
      networkmanager.enable = currentHost.networkManager;

      useDHCP =
        !currentHost.networkManager
        && lib.any (icfg: icfg.dhcp) (lib.attrValues currentHost.interfaces);

      interfaces =
        lib.mkIf (!currentHost.networkManager)
        (lib.mapAttrs (iface: icfg: {
          ipv4.addresses =
            lib.mkIf (icfg.address != null)
            [{
              inherit (icfg) address;
              prefixLength = 24;
            }];
        })
        (lib.filterAttrs (_: icfg: icfg.address != null) currentHost.interfaces));

      defaultGateway = let
        staticInterfaces = lib.filterAttrs (_: icfg: icfg.address != null) currentHost.interfaces;
        gateways = lib.filter (g: g != null)
          (lib.mapAttrsToList (_: icfg: icfg.gateway) staticInterfaces);
      in
        lib.mkIf (gateways != []) (lib.head gateways);

      nameservers = ["8.8.8.8" "1.1.1.1"];

      wireguard.interfaces =
        lib.mkIf (currentHost.wireguard != null)
        (lib.mapAttrs (wgName: wgIface: {
          ips = ["${wgIface.ip}/24"];
          privateKeyFile = cfg.wireguardPrivateKeyFile;
          listenPort = lib.mkIf wgIface.isServer wgIface.listenPort;

          peers = let
            others = lib.filterAttrs (name: _: name != currentHostName)
              (hostsOnNetwork wgIface.network);
          in
            if wgIface.isServer
            then
              lib.mapAttrsToList (name: host: let
                peer = ifaceForNetwork host wgIface.network;
              in {
                publicKey = host.wireguard.publicKey;
                allowedIPs = ["${peer.ip}/32"] ++ peer.routedNetworks;
              })
              others
            else let
              server = findServerOnNetwork wgIface.network;
            in
              lib.optional (server != null) (let
                serverIface = ifaceForNetwork server.value wgIface.network;
              in {
                publicKey = server.value.wireguard.publicKey;
                allowedIPs = [wgIface.network];
                endpoint = serverIface.endpoint;
                persistentKeepalive = wgIface.persistentKeepalive;
              });
        })
        currentHost.wireguard.interfaces);
    };

    networking.firewall =
      lib.mkIf (currentHost.wireguard != null)
      {
        allowedUDPPorts = lib.flatten (
          lib.mapAttrsToList (_: wgIface:
            lib.optional wgIface.isServer wgIface.listenPort
          ) currentHost.wireguard.interfaces
        );
      };

    boot.kernel.sysctl =
      lib.mkIf
      (
        (currentHost.wireguard != null
          && lib.any (iface: iface.isServer) (lib.attrValues currentHost.wireguard.interfaces))
        || currentHost.routing != null
      )
      {
        "net.ipv4.ip_forward" = true;
      };

    networking.nat =
      lib.mkIf (currentHost.routing != null && currentHost.routing.nat != {})
      {
        enable = true;
        externalInterface =
          let
            firstEntry = lib.head (lib.attrValues currentHost.routing.nat);
          in
            firstEntry.outInterface;
        internalInterfaces =
          lib.unique (
            lib.mapAttrsToList (_: entry: entry.outInterface) currentHost.routing.nat
          );
        internalIPs =
          lib.mapAttrsToList (cidr: _: cidr) currentHost.routing.nat;
      };

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      publish =
        lib.mkIf (!currentHost.networkManager)
        {
          enable = true;
          hinfo = true;
          addresses = true;
          workstation = true;
        };
      openFirewall = true;
    };
  };
}
