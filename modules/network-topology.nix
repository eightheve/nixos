{
  lib,
  ...
}: {
  options.site.topology = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        managed = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether this host is managed by this NixOS config";
        };

        networkManager = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };

        interfaces = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              dhcp = lib.mkOption {
                type = lib.types.bool;
                default = true;
              };
              address = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
              };
              gateway = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
              };
            };
          });
          default = {};
        };

        wireguard = lib.mkOption {
          type = lib.types.nullOr (lib.types.submodule {
            options = {
              publicKey = lib.mkOption {
                type = lib.types.str;
              };
              interfaces = lib.mkOption {
                type = lib.types.attrsOf (lib.types.submodule {
                  options = {
                    ip = lib.mkOption {
                      type = lib.types.str;
                    };
                    isServer = lib.mkOption {
                      type = lib.types.bool;
                      default = false;
                    };
                    listenPort = lib.mkOption {
                      type = lib.types.int;
                      default = 51820;
                    };
                    endpoint = lib.mkOption {
                      type = lib.types.nullOr lib.types.str;
                      default = null;
                      description = "External endpoint (host:port) for server interfaces";
                    };
                    network = lib.mkOption {
                      type = lib.types.str;
                      description = "CIDR for this WireGuard network (determines client allowedIPs)";
                    };
                    persistentKeepalive = lib.mkOption {
                      type = lib.types.int;
                      default = 25;
                    };
                    routedNetworks = lib.mkOption {
                      type = lib.types.listOf lib.types.str;
                      default = [];
                      description = "Additional CIDRs routed through this interface (added to server-side allowedIPs)";
                    };
                  };
                });
              };
            };
          });
          default = null;
        };

        routing = lib.mkOption {
          type = lib.types.nullOr (lib.types.submodule {
            options = {
              nat = lib.mkOption {
                type = lib.types.attrsOf (lib.types.submodule {
                  options = {
                    outInterface = lib.mkOption {
                      type = lib.types.str;
                      description = "Outbound interface for masquerading";
                    };
                  };
                });
                default = {};
                description = "NAT rules: keys are source CIDRs, values specify the outbound interface";
              };
            };
          });
          default = null;
        };
      };
    });
    default = {};
  };

  config.site.topology = {
    KAZOOIE = {
      networkManager = false;
      interfaces = {
        enp1s0 = {
          dhcp = true;
        };
      };
      wireguard = {
        publicKey = "1I3PO1MgFdqffo816H34YalYgnCrwPo3ssBbsLTxzBg=";
        interfaces = {
          wg0 = {
            ip = "10.100.0.1";
            isServer = true;
            listenPort = 51820;
            endpoint = "5.161.238.34:51820";
            network = "10.0.0.0/8";
          };
        };
      };
    };

    SAOTOME = {
      networkManager = false;
      interfaces = {
        eno3 = {
          dhcp = true;
        };
      };
      wireguard = {
        publicKey = "0hrwVOfaPGTs2bfHoGrHroHGqG2aJiiu8JO9o5/K0xg=";
        interfaces = {
          wg0 = {
            ip = "10.100.0.2";
            network = "10.0.0.0/8";
          };
        };
      };
    };

    PASSENGER = {
      networkManager = false;
      interfaces = {
        enp12s0 = {
          dhcp = true;
        };
      };
      wireguard = {
        publicKey = "rqWyPEf6SEPp1QJ7lxVqq920pIo6UFddIbwZOO5DR3I=";
        interfaces = {
          wg0 = {
            ip = "10.100.1.1";
            network = "10.0.0.0/8";
          };
        };
      };
    };

    SATELLITE = {
      networkManager = true;
    };

    FORTRESS = {
      managed = false;
      wireguard = {
        publicKey = "62AFcf79kP5HyAoj1IRaj4fwnJTYvfK0hhTYjSMQg0w=";
        interfaces = {
          wg0 = {
            ip = "10.100.1.2";
            network = "10.0.0.0/8";
          };
        };
      };
    };

    HP1 = {
      networkManager = false;
      interfaces = {
        eno1.dhcp = true;
        eno2.address = "10.200.0.1";
        eno3.address = "10.200.1.1";
      };
      wireguard = {
        publicKey = "PLACEHOLDER";
        interfaces = {
          wg0 = {
            ip = "10.100.2.1";
            network = "10.0.0.0/8";
            routedNetworks = ["10.200.0.0/16"];
          };
        };
      };
      routing = {
        nat = {
          "10.200.0.0/24".outInterface = "eno1";
          "10.200.1.0/24".outInterface = "eno1";
        };
      };
    };

    HP2 = {
      networkManager = false;
      interfaces = {
        eno1 = {
          address = "10.200.0.2";
          gateway = "10.200.0.1";
        };
      };
    };

    HP3 = {
      networkManager = false;
      interfaces = {
        eno1 = {
          address = "10.200.1.2";
          gateway = "10.200.1.1";
        };
      };
    };
  };
}
