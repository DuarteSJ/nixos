# Aggregates user scripts
{ pkgs, ... }:

{
	imports = [
		./zsh.nix
		./alacritty.nix
		./cava.nix
	];
}
