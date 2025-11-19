{lib, ...}: {
  imports = [
    ./hyprland.nix
    ./hyprlock.nix
    ./waybar.nix
    ./rofi.nix
    ./dunst.nix
  ];

  options.monitors = lib.mkOption {
    type = lib.types.attrs;
    default = {};
    description = "Monitor identifiers";
  };

  config.monitors = {
    external = "DP-3";
    laptop = "eDP-1";
  };
}
