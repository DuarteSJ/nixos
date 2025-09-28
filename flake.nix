{
	description = "My system's flake";
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
# nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		hyprland.url = "github:hyprwm/Hyprland";
		nix-colors.url = "github:misterio77/nix-colors";
		spicetify-nix.url = "github:Gerg-L/spicetify-nix";
	};
	outputs = { nixpkgs, home-manager, ... } @ inputs:
	{
		nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
			specialArgs = { inherit inputs; };
			modules = [
				./system/configuration.nix
					home-manager.nixosModules.home-manager
					{
						home-manager.useGlobalPkgs = true;
						home-manager.useUserPackages = true;
						home-manager.extraSpecialArgs = { inherit inputs; };
						home-manager.users.duartesj = import ./home;
					}

                    {
                        nixpkgs.config.allowUnfree = true;
                    }

			];
		};
	};
}
