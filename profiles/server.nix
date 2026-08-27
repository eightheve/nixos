{
  config,
  lib,
  ...
}:
let
  cfg = config.site.profiles.server;
in
{
  options.site.profiles.server = {
    enable = lib.mkEnableOption "server profile (headless server base settings)";
  };

  config = lib.mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;
      defaults.email = "sana@doppel.moe";
    };

    site.modules.ssh = {
      enable = true;
      openFirewall = true;
    };

    # sshd jail with escalating bans for repeat offenders. The sshd jail is
    # enabled by default in the NixOS fail2ban module.
    services.fail2ban = {
      enable = true;
      maxretry = 5;
      bantime = "1h";
      bantime-increment = {
        enable = true;
        maxtime = "168h";
      };
    };
  };
}
