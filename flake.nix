{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    hjem.url = "github:feel-co/hjem";
    hjem.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    impermanence.inputs.nixpkgs.follows = "";
    impermanence.inputs.home-manager.follows = "";
    sana-website = {
      url = "github:eightheve/sana-website";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fathom.url = "github:eightheve/fathom";
    vintagestory-server.url = "github:eightheve/vs-nix-bot";
    mc-whitelist.url = "github:eightheve/mc-whitelist";
    wayfinder.url = "github:eightheve/wayfinder";
    maki.url = "github:tontinton/maki";
    maki.inputs.nixpkgs.url = "github:nixos/nixpkgs/2f5a153c270b70cb0f8c11f46d96d6d3bc39f4e3";
    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
    katydid = {
      url = "github:cnwnc/katydid";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    essentia-tagger.url = "github:cnwnc/essentia-tagger";
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      hjem,
      fathom,
      wayfinder,
      vintagestory-server,
      mc-whitelist,
      maki,
      git-hooks,
      sana-website,
      ...
    }@inputs:
    let
      hostNames = builtins.attrNames (builtins.readDir ./hosts);

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      hostSystems = {
        KAZOOIE = "x86_64-linux";
        PASSENGER = "x86_64-linux";
        SAOTOME = "x86_64-linux";
        SILFA = "aarch64-linux";
      };

      mkHost =
        hostname:
        let
          system = hostSystems.${hostname} or "x86_64-linux";
          pkgs-unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
            config.cudaSupport = system == "x86_64-linux";
          };
        in
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
            inherit pkgs-unstable;
            site = {
              lib = import ./modules/lib.nix { inherit (nixpkgs) lib; };
            };
          };
          modules = [
            {
              nixpkgs.hostPlatform = nixpkgs.lib.mkDefault system;
            }
            ./profiles
            ./modules
            ./users
            ./hosts/${hostname}
            hjem.nixosModules.default
            fathom.nixosModules.default
            wayfinder.nixosModules.default
            vintagestory-server.nixosModules.default
            mc-whitelist.nixosModules.default
            sana-website.nixosModules.default
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
      devShells = nixpkgs.lib.genAttrs supportedSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          preCommit = git-hooks.lib.${system}.run {
            src = ./.;
            hooks.nixfmt = {
              enable = true;
              args = [ "--check" ];
            };
          };
        in
        {
          default = pkgs.mkShell {
            inherit (preCommit) shellHook;
            buildInputs = [ pkgs.git ] ++ preCommit.enabledPackages;
          };
        }
      );
    };
}
