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
    ./zsh.nix
    ./hyprland.nix
    ./hyprlock.nix
    ./alacritty.nix
    ./waybar.nix
    ./rofi.nix
    ./cava.nix
    ./scripts/switch-bg.nix
    ./scripts/timer.nix
    ./scripts/alt-tab.nix
    ./scripts/toggle-mic.nix
  ];

  colorScheme = inputs.nix-colors.colorSchemes.nord;

  programs.home-manager.enable = true;
}

