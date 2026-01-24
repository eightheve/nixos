{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    nvf-nixpkgs.url = "github:NixOS/nixpkgs/c0b0e0fddf73fd517c3471e546c0df87a42d53f4";
    nvf.url = "github:notashelf/nvf";
    nvf.inputs.nixpkgs.follows = "nvf-nixpkgs";
    nixcord.url = "github:kaylorben/nixcord";
    sana-website = {
      url = "github:eightheve/sana-website";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vintagestory-nix = {
      url = "github:PierreBorine/vintagestory-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    hostNames = builtins.attrNames (builtins.readDir ./hosts);

    mkHost = hostname:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          ./modules/nixos
          ./users

          ./common.nix

          ./hosts/${hostname}
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              backupFileExtension = "backup";
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {inherit inputs;};
              sharedModules = [./modules/home];
            };
          }
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
