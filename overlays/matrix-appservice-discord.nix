# overlays/matrix-appservice-discord.nix
final: prev: {
  matrix-appservice-discord = prev.matrix-appservice-discord.overrideAttrs (old: rec {
    version = "0-unstable-2026-03-01"; # use the commit date

    src = final.fetchFromGitHub {
      owner = "weirdreality";
      repo = "matrix-appservice-discord";
      rev = "54084ec3160b2503578f60191dd70504b44d60a8";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };

    offlineCache = final.fetchYarnDeps {
      yarnLock = "${src}/yarn.lock";
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
  });
}
