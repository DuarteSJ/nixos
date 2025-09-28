{ config, pkgs, inputs, ... }:
{
	home.username = "duartesj";
	home.homeDirectory = "/home/duartesj";
	home.stateVersion = "24.11";

	imports = [
		inputs.nix-colors.homeManagerModules.default
			./environment.nix
			./packages.nix
			./git.nix
	] ++ (import ./desktop) ++ (import ./terminal) ++ (import ./scripts);
	colorScheme = inputs.nix-colors.colorSchemes.nord;

	programs.home-manager.enable = true;
}

