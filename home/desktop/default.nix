{lib, ...}: let
  monitorType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Monitor identifier.";
      };
      mode = lib.mkOption {
        type = lib.types.str;
        default = "1920x1080@60";
        description = "Resolution and refresh rate.";
      };
      position = lib.mkOption {
        type = lib.types.str;
        default = "0x0";
        description = "Position of the monitor.";
      };
      scale = lib.mkOption {
        type = lib.types.str;
        default = "1";
        description = "Scaling factor for the monitor.";
      };
    };
  };
in {
  imports = [
    ./hyprland.nix
    ./hyprlock.nix
    ./waybar.nix
    ./rofi.nix
    ./dunst.nix
  ];

  options.monitors = lib.mkOption {
    type = lib.types.attrsOf monitorType;
    default = {};
    description = "Monitor configurations";
  };

  config.monitors = rec {
    laptop = {
      name = "eDP-1";
      mode = "1920x1200@59.95";
    };
    other = {
      name = "DP-3";
      mode = "1920x1080@60";
      position = "1920x0";
    };
    home = {
      name = "DP-3";
      mode = "1920x1080@119.98";
      position = "1920x0";
    };
    external = home;
  };
}
