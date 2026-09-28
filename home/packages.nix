{
  pkgs,
  inputs,
  ...
}: {
  home.packages =
    (with pkgs; [
      # Nvidia drivers
      nvidia-vaapi-driver

      # CLI tools
      gh
      curl
      eza
      ripgrep
      jq
      zip
      unzip
      wl-clipboard
      brightnessctl
      playerctl
      alejandra
      statix
      mcp-nixos
      ffmpeg
      swayimg
      mpv
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

      # Applications
      obsidian
      scrcpy
      vial
      stremio-linux-shell

      # LaTeX
      texlive.combined.scheme-full
      perl
    ])
    ++ [
      inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
}
