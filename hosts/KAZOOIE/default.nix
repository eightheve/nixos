{ pkgs,
  pkgs-unstable,
  config,
  lib,
  ...
}: {
  imports = [
    ./hardware.nix
  ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  myModules.networking = {
    enable = true;
    hostName = "sys";
  };
  networking.domain = "doppel.moe";

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "claude-code"
  ];

  environment.systemPackages = [
    pkgs.claude-code
    pkgs-unstable.mcp-nixos
  ];

  myModules.ssh = {
    enable = true;
    openFirewall = true;
    ports = [2222];
  };

  myModules = {
    navidrome.nginx = {
      enable = true;
      upstream = "http://10.100.0.2:4533";
    };
    slskd.nginx = {
      enable = true;
      upstream = "http://10.100.0.2:5030";
    };
    sanaWebsite.enable = true;
    matrix.synapse.enable = true;
  };
  
  services.postfix.enable = false;
  services.opensmtpd = {
    enable = true;
    setSendmail = true;
    serverConfiguration = ''
      pki sys.doppel.moe cert "/etc/opensmtpd/sys.doppel.moe/fullchain.pem"
      pki sys.doppel.moe key  "/etc/opensmtpd/sys.doppel.moe/key.pem"

      listen on lo
      listen on enp1s0 tls pki sys.doppel.moe

      action "local" maildir
      action "outbound" relay

      match from local for local action "local"
      match from any for domain "sys.doppel.moe" action "local"
      match from local for any action "outbound"
    '';
  };

  security.acme = {
    certs."sys.doppel.moe" = {
      email = "sana@doppel.moe";
      webroot = "sys.doppel.moe";
      group = "smtpd";
      postRun = ''
        mkdir -p /etc/opensmtpd/sys.doppel.moe
        cp /var/lib/acme/sys.doppel.moe/* /etc/opensmtpd/sys.doppel.moe/
        chmod 640 /etc/opensmtpd/sys.doppel.moe/*
        chown root:smtpd -R /etc/opensmtpd/sys.doppel.moe
      '';
    };
  };

  systemd.services.opensmtpd-certs = {
    description = "Copy ACME certs for opensmtpd";
    after = [ "acme-finished-mail.sys.doppel.moe.target" ];
    wantedBy = [ "opensmtpd.service" ];
    before = [ "opensmtpd.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir -p /etc/opensmtpd/sys.doppel.moe
      cp /var/lib/acme/sys.doppel.moe/fullchain.pem /etc/opensmtpd/sys.doppel.moe/fullchain.pem
      cp /var/lib/acme/sys.doppel.moe/key.pem /etc/opensmtpd/sys.doppel.moe/key.pem
      chmod 640 /etc/opensmtpd/sys.doppel.moe/*.pem
      chown root:smtpd /etc/opensmtpd/sys.doppel.moe/*.pem
    '';
  };

  system.activationScripts.maildirSkeleton = ''
    mkdir -p /etc/skel/Maildir/{new,cur,tmp}
  '';

  myModules.wireguard = {
    enable = true;
  };

  networking.firewall = {
    allowedTCPPorts = [443 80 25];
  };

  system.stateVersion = "25.05";
}
