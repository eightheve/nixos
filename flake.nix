{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    nvf.url = "github:notashelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixpkgs";
    nixcord.url = "github:kaylorben/nixcord";
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
