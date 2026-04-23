{pkgs, ...}: {
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
    # TODO: try to fetch this. was giving 404
    # stremio-linux-shell

    # LaTeX
    texlive.combined.scheme-full
    perl
  ];
}
