{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git
    curl
    home-manager
    alacritty
    eza
    fastfetch
    waybar
    rofi-wayland
    swww
    dunst
    hyprlock
    wl-clipboard
    brightnessctl
    playerctl
    grim
    slurp
    cava
    pavucontrol
    nerd-fonts.jetbrains-mono
    nordzy-cursor-theme
    blueman
    networkmanagerapplet
    obs-studio
  ];
}
