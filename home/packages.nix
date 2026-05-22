{
  pkgs,
  inputs,
  system,
  ...
}: {
  home.packages = (with pkgs; [
    # Nvidia drivers
    nvidia-vaapi-driver

    # CLI tools
    git
    gh
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
  ]) ++ [
    inputs.claude-code.packages.${system}.default
  ];
}
