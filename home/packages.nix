{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    eza
    fastfetch
    curl
    wl-clipboard
    cava
  ];
}


