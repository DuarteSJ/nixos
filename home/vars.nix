{
  lib,
  pkgs,
  config,
  ...
}: {
  options.vars = {
    rounding = lib.mkOption {
      description = "Corner radius";
      type = lib.types.int;
      default = 2;
    };

    gapsOuter = lib.mkOption {
      description = "Outer gap.";
      type = lib.types.int;
      default = 24;
    };

    gapsInner = lib.mkOption {
      description = "Inner gap. Derived as half the outer gap; single source for the gaps/2 relationship reused across hyprland/waybar.";
      type = lib.types.int;
      default = config.vars.gapsOuter / 2;
    };

    font = lib.mkOption {
      description = "Font configuration";
      type = lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            default = "JetBrainsMono Nerd Font";
          };
          size = lib.mkOption {
            type = lib.types.float;
            default = 12.5;
          };
        };
      };
    };

    terminal = lib.mkOption {
      description = "Default terminal command";
      type = lib.types.str;
      default = "alacritty";
    };

    editor = lib.mkOption {
      description = "Default editor command";
      type = lib.types.str;
      default = "nvim";
    };

    theme = lib.mkOption {
      description = "Active color scheme slug (must exist in themes; see theme.nix).";
      type = lib.types.str;
      default = "nord";
    };

    cursor = lib.mkOption {
      description = "Cursor theme configuration";
      type = lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            default = "Bibata-Modern-Ice";
          };
          size = lib.mkOption {
            type = lib.types.int;
            default = 24;
          };
        };
      };
    };

    paths = lib.mkOption {
      description = "Common user paths";
      type = lib.types.submodule {
        options = {
          notes = lib.mkOption {
            type = lib.types.str;
            default = "~/notes";
          };
          wallpapers = lib.mkOption {
            type = lib.types.str;
            default = "$HOME/Pictures/wallpapers";
          };
        };
      };
    };
  };

  # Single cursor source -> GTK, X11/XCursor, and Hyprland (hyprcursor).
  config.home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = config.vars.cursor.name;
    size = config.vars.cursor.size;
    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
  };
}
