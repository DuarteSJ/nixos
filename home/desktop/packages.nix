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
      # (git, home-manager, alacritty omitted: installed by their
      #  programs.<name>.enable modules.)
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
      inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
}
