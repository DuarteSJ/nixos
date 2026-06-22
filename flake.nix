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

    mkHost = hostPath:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules = [
          hostPath
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {inherit inputs;};
            };
          }
        ];
      };
  in {
    nixosConfigurations = {
      desktop = mkHost ./hosts/desktop/default.nix;
      homelab = mkHost ./hosts/homelab/default.nix;
    };
  };
}
