{
  pkgs,
  inputs,
  system,
  ...
}: {
  home.packages =
    (with pkgs; [
      # Nvidia drivers
      nvidia-vaapi-driver

      # CLI tools
      # (git, home-manager, alacritty omitted: installed by their
      #  programs.<name>.enable modules.)
      gh
      curl
      eza
      fastfetch
      wl-clipboard
      brightnessctl
      playerctl
      ripgrep
      alejandra
      statix
      mcp-nixos
      ffmpeg
      swayimg
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

      # Applications
      telegram-desktop
      obsidian
      scrcpy
      vial
      stremio-linux-shell

      # LaTeX
      texlive.combined.scheme-full
      perl
    ])
    ++ [
      inputs.claude-code.packages.${system}.default
    ];
}
