{ pkgs, inputs, system, ... }:

let
  unstable = import inputs.nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };
in
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
    hyprpaper
    dunst
    hyprlock
    wl-clipboard
    brightnessctl
    playerctl
    cava
    pavucontrol
    nerd-fonts.jetbrains-mono
    nordzy-cursor-theme
    blueman
    networkmanagerapplet
    obs-studio
    telegram-desktop
    hyprpicker
    texlive.combined.scheme-full
    perl
    ripgrep
    obsidian
    vial
    alejandra
    scrcpy
    stremio
    wireguard-tools
    ffmpeg
    feh
    mpv
    unstable.code-cursor
  ];
}
