{inputs, ...}: {
  imports = [
    inputs.spicetify-nix.homeManagerModules.default

    # window manager / GUI shell
    ./monitors.nix
    ./hyprland
    ./hyprlock.nix
    ./waybar.nix
    ./rofi.nix
    ./dunst.nix
    ./hyprpaper.nix
    ./hyprshot.nix
    ./hyprsunset.nix

    # relocated GUI modules
    ./cursor.nix
    ./scripts
    ./apps
    ./packages.nix
    ./alacritty.nix
    ./cava.nix
  ];
}
