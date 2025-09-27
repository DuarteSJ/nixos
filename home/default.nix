{ config, pkgs, ... }:
{
  home.username = "duartesj";
  home.homeDirectory = "/home/duartesj";
  home.stateVersion = "24.11";

  imports = [
    ./git.nix
    ./zsh.nix
    ./packages.nix
    ./environment.nix
  ];

  programs.home-manager.enable = true;
}

