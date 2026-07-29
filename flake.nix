{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    hjem.url = "github:feel-co/hjem";
    hjem.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
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
  };

  outputs = {
    nixpkgs,
    nixpkgs-unstable,
    hjem,
    agenix,
    fathom,
    wayfinder,
    vintagestory-server,
    mc-whitelist,
    ...
  } @ inputs: let
    hostNames = builtins.attrNames (builtins.readDir ./hosts);

    system = "x86_64-linux";
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
      config.cudaSupport = true;
    };

    mkHost = hostname:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          inherit pkgs-unstable;
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
  in {
    nixosConfigurations = builtins.listToAttrs (
      map (name: {
        inherit name;
        value = mkHost name;
      })
      hostNames
    );
  };
}
