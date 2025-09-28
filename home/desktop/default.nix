{ pkgs, ... }:

{
	imports = [
		./hyprland.nix
		./hyprlock.nix
		./waybar.nix
		./rofi.nix
		./dunst.nix
	];
}

