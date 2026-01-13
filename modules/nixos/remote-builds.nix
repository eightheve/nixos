{
  config,
  lib,
  ...
}: let
  cfg = config.myModules.remoteBuilds;

  hostModule = lib.types.submodule {
    options = {
      hostName = lib.mkOption {
        type = lib.types.str;
        description = "IP address or hostname";
      };
      system = lib.mkOption {
        type = lib.types.str;
        default = "x86_64-linux";
      };
      maxJobs = lib.mkOption {
        type = lib.types.int;
        default = 4;
      };
      speedFactor = lib.mkOption {
        type = lib.types.int;
        default = 2;
      };
      supportedFeatures = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      };
      identityFile = lib.mkOption {
        type = lib.types.str;
        default = "/root/.ssh/nixremote";
      };
      identitiesOnly = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      sshUser = lib.mkOption {
        type = lib.types.str;
        default = "nixremote";
      };
      proxyJump = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "SSH jump host";
      };
    };
  };

  mkSshConfig = name: host: ''
    Host ${name}
      HostName ${host.hostName}
      ${lib.optionalString host.identitiesOnly "IdentitiesOnly yes"}
      ${lib.optionalString (host.proxyJump != null) "ProxyJump  ${host.proxyJump}"}
      IdentityFile ${host.identityFile}
      User ${host.sshUser}
  '';

  mkBuildMachine = name: host: {
    hostName = name;
    inherit (host) system maxJobs speedFactor supportedFeatures;
    protocol = "ssh-ng";
  };
in {
  options.myModules.remoteBuilds = {
    builder = {
      enable = lib.mkEnableOption "be a remote builder";

      authorizedRootKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAThaVtAb1QhxVxYuORHd71O58Y5bLOLdkUr8A9N4yIl root@SAOTOME"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICkb4O78MsBxBrHc/VFtDcO35/G26kYiRWVYBbN/f5Iz root@PASSENGER"
        ];
      };

      serviceUserName = lib.mkOption {
        type = lib.types.str;
        default = "nixremote";
      };
    };

    user = {
      enable = lib.mkEnableOption "use builders";

      hosts = lib.mkOption {
        type = lib.types.attrsOf hostModule;
        default = {};
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.builder.enable {
      users.users.${cfg.builder.serviceUserName} = {
        isNormalUser = true;
        home = "/home/${cfg.builder.serviceUserName}";
        createHome = true;
        openssh.authorizedKeys.keys = cfg.builder.authorizedRootKeys;
      };

      systemd.tmpfiles.rules = let
        username = cfg.builder.serviceUserName;
      in [
        "z /home/${username} 0555 ${username} ${username} -"
        "z /home/${username}/.ssh/ 0555 ${username} ${username} - "
      ];

      nix.settings.trusted-users = [cfg.builder.serviceUserName];
    })
    (lib.mkIf cfg.user.enable {
      programs.ssh.extraConfig = lib.concatStrings (
        lib.mapAttrsToList mkSshConfig cfg.user.hosts
      );

      nix = {
        buildMachines = lib.mapAttrsToList mkBuildMachine cfg.user.hosts;
        distributedBuilds = true;
        extraOptions = ''
          builders-use-substitutes = true
        '';
      };
    })
  ];
}
