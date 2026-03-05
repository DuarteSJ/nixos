{
  description = "My system's flake";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stremio.url = "github:NixOS/nixpkgs/nixos-25.05"; # TODO: update when stremio is updated in nixpkgs

    # WM / tooling
    hyprland.url = "github:hyprwm/Hyprland";
    nix-colors.url = "github:misterio77/nix-colors";
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager?ref=release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Neovim framework
    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    ...
  } @ inputs:
  let
    system = "x86_64-linux";
  in
  {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit inputs system;
      };

      modules = [
        ./system/configuration.nix

        # Home Manager as NixOS module
        home-manager.nixosModules.home-manager

        # Global nixpkgs config
        {
          nixpkgs.config.allowUnfree = true;
        }

        # Home Manager config
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.extraSpecialArgs = {
            inherit inputs system;
          };

          home-manager.users.duartesj = import ./home;
        }
      ];
    };
  };
}
