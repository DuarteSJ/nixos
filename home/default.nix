{ config, pkgs, ... }:
{
  home.username = "duartesj";
  home.homeDirectory = "/home/duartesj";
  home.stateVersion = "24.11";

  imports = [
    ./environment.nix
    ./packages.nix
    ./git.nix
    ./zsh.nix
    ./hyprland.nix
  ];

  programs.home-manager.enable = true;
}

