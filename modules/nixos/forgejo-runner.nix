{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myModules.forgejoRunner;

  pkgs-glibc239 = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/2c36ece932b8c0040893990da00034e46c33e3e7.tar.gz";
    sha256 = "sha256-XvKKl01RaLL8k/3CXS1NazdsxZ7B+5hIY6j9JNqdl7c=";
  }) {system = "x86_64-linux";};
in {
  options.myModules.forgejoRunner = {
    enable = lib.mkEnableOption "forgejo runner for ampersand sys";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.trustedInterfaces = ["br-*" "docker*"];

    virtualisation.docker.enable = true;

    services.gitea-actions-runner = {
      package = pkgs.forgejo-runner;
      instances.ampersandSys = {
        enable = true;
        name = "ampersandSys";
        tokenFile = "/etc/ampersandsys-forgejo-token.env";
        url = "https://codeberg.org/";
        labels = [
          "ubuntu-latest:docker://ghcr.io/catthehacker/ubuntu:act-22.04"
          "native:host"
        ];
        hostPackages = with pkgs;
          [
            bash
            coreutils
            curl
            gawk
            gitMinimal
            gnused
            nodejs
            wget
          ]
          ++ [pkgs-glibc239.glibc];
      };
    };
  };
}
