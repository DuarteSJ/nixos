{
  pkgs,
  inputs,
  system,
  ...
}: let
  unstable = import inputs.nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };
in {
  home.packages = with pkgs; [
    # Nvidia drivers
    nvidia-vaapi-driver

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
    statix
    ffmpeg
    feh
    mpv
    jq
    usbutils

    # Desktop utilities
    hyprpicker
    pavucontrol
    blueman
    networkmanagerapplet
    cava
    rofi
    hyprshade

    # Fonts & themes
    nerd-fonts.jetbrains-mono
    nordzy-cursor-theme

    # Applications
    alacritty
    telegram-desktop
    obsidian
    scrcpy
    vial
    stremio-linux-shell

    # LaTeX
    texlive.combined.scheme-full
    perl

    # Unstable channel
    unstable.code-cursor
  ];
}
