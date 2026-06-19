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

    # Claude Code. Intentionally does NOT `follows` our nixpkgs: claude-code-nix
    # pins its own (unstable) nixpkgs to ship fresh builds, so a second nixpkgs
    # is evaluated for this input only — accepted tradeoff for up-to-date builds.
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
        inherit inputs;
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
              inherit inputs;
            };
          };

          home-manager.users.duartesj = import ./home;
        }
      ];
    };
  };
}
