{
  description = "My system's flake";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # WM / tooling
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager?ref=release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Neovim framework
    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Claude Code (fresh builds)
    claude-code.url = "github:sadjow/claude-code-nix";
  };

  outputs = {
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    system = "x86_64-linux";
  in {
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
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {
              inherit inputs system;
            };
          };

          home-manager.users.duartesj = import ./home;
        }
      ];
    };
  };
}
