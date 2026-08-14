{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    hjem.url = "github:feel-co/hjem";
    hjem.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    sana-website = {
      url = "github:eightheve/sana-website";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fathom.url = "github:eightheve/fathom";
    vintagestory-server.url = "github:eightheve/vs-nix-bot";
    mc-whitelist.url = "github:eightheve/mc-whitelist";
    wayfinder.url = "github:eightheve/wayfinder";
    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      hjem,
      agenix,
      fathom,
      wayfinder,
      vintagestory-server,
      mc-whitelist,
      git-hooks,
      ...
    }@inputs:
    let
      hostNames = builtins.attrNames (builtins.readDir ./hosts);

      system = "x86_64-linux";
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
        config.cudaSupport = true;
      };

      pkgs = nixpkgs.legacyPackages.${system};

      preCommit = git-hooks.lib.${system}.run {
        src = ./.;
        hooks.nixfmt = {
          enable = true;
          args = [ "--check" ];
        };
      };

      mkHost =
        hostname:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            inherit pkgs-unstable;
            site = {
              lib = import ./modules/lib.nix { inherit (nixpkgs) lib; };
            };
          };
          modules = [
            ./profiles
            ./modules
            ./users
            ./hosts/${hostname}
            hjem.nixosModules.default
            agenix.nixosModules.default
            fathom.nixosModules.default
            wayfinder.nixosModules.default
            vintagestory-server.nixosModules.default
            mc-whitelist.nixosModules.default
          ];
        };
    in
    {
      nixosConfigurations = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = mkHost name;
        }) hostNames
      );

      # Enter once with `nix develop` to install the git pre-commit hook.
      # The hook then checks formatting of staged .nix files on commit.
      devShells.${system}.default = pkgs.mkShell {
        inherit (preCommit) shellHook;
        buildInputs = [ pkgs.git ] ++ preCommit.enabledPackages;
      };
    };
}
