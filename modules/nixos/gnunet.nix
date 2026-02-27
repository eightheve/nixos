{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myModules.gnunet;
  stateDir = "/var/lib/gnunet";
  tcp.port = 2086;
  udp.port = 2086;
  configFile = ''
    [PATHS]
    GNUNET_HOME = ${stateDir}
    GNUNET_RUNTIME_DIR = /run/gnunet
    GNUNET_USER_RUNTIME_DIR = /run/gnunet
    GNUNET_DATA_HOME = ${stateDir}/data

    [transport-udp]
    PORT = ${toString udp.port}
    ADVERTISED_PORT = ${toString udp.port}

    [transport-tcp]
    PORT = ${toString tcp.port}
    ADVERTISED_PORT = ${toString tcp.port}
  '';
in {
  options.myModules.gnunet = {
    enable = lib.mkEnableOption "gnunet";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gnunet
    ];

    users.users.gnunet = {
      isSystemUser = true;
      home = "/var/lib/gnunet";
      createHome = true;
      homeMode = "750";
    };

    environment.etc."gnunet.conf".text = configFile;

    systemd.services.gnunet = {
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      restartTriggers = [config.environment.etc."gnunet.conf".source];
      path = [
        pkgs.gnunet
        pkgs.miniupnpc
      ];
      serviceConfig.ExecStart = "${pkgs.gnunet}/lib/gnunet/libexec/gnunet-service-arm -c /etc/gnunet.conf";
      serviceConfig.User = "gnunet";
      serviceConfig.UMask = "0007";
      serviceConfig.WorkingDirectory = stateDir;
      serviceConfig.RuntimeDirectory = "gnunet";
      serviceConfig.StateDirectory = "gnunet";
    };
  };
}
