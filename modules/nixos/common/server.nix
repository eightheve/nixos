{
  config,
  pkgs,
  lib,
  ...
}: {
  security.acme = {
    acceptTerms = true;
    defaults.email = "sana@doppel.moe";
  };
}
