{lib, ...}: {
  options.vars = {
    rounding = lib.mkOption {
      description = "Corner radius";
      type = lib.types.int;
      default = 2;
    };

    gaps = lib.mkOption {
      description = "Gaps configuration";
      type = lib.types.int;
      default = 4;
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

    cursor = lib.mkOption {
      description = "Cursor theme configuration";
      type = lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            default = "Nordzy-cursors";
          };
          size = lib.mkOption {
            type = lib.types.int;
            default = 26;
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

  config.vars = {
    rounding = 2;
    gaps = 4;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12.5;
    };
    terminal = "alacritty";
    editor = "nvim";
    cursor = {
      name = "Nordzy-cursors";
      size = 26;
    };
    paths = {
      notes = "~/notes";
      wallpapers = "$HOME/Pictures/wallpapers";
    };
  };
}
