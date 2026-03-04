{ pkgs, inputs, system, ... }:

let
  unstable = import inputs.nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };
in
{
  home.packages = with pkgs; [
    # CLI tools
    git
    curl
    home-manager
    eza
    fastfetch
    wl-clipboard
    brightnessctl
    playerctl
    ripgrep
    alejandra
    ffmpeg
    feh
    mpv
    jq

    # Desktop utilities
    hyprpicker
    pavucontrol
    blueman
    networkmanagerapplet
    cava
    rofi

    # Fonts & themes
    nerd-fonts.jetbrains-mono
    nordzy-cursor-theme

    # Applications
    alacritty
    obs-studio
    telegram-desktop
    obsidian
    scrcpy
    vial

    # LaTeX
    texlive.combined.scheme-full
    perl

    # Unstable channel
    unstable.code-cursor
  ];
}
