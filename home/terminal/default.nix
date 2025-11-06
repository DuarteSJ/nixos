# Aggregates user scripts
{pkgs, ...}: {
  imports = [
    ./zsh.nix
    ./bash.nix
    ./alacritty.nix
    ./cava.nix
    ./fastfetch.nix
    ./bat.nix
    ./btop.nix
    ./starship.nix
  ];
}
