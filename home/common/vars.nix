# Knobs read by more than one module.  Anything with a single consumer lives
# at that consumer instead (gaps in hyprland, bar radius in quickshell, cursor
# in cursor.nix, paths next to what uses them).
{lib, ...}: {
  options.vars = {
    rounding = lib.mkOption {
      description = ''
        Surface corner radius: hyprland windows, notifications, the
        launcher.  On the Hyprland side it enters through the single
        `baseline` table in home/laptop/desktop/hyprland/default.nix, which feeds
        the static config, focus mode's restore and the gap keys alike.

        Anything nested INSIDE a surface (the launcher's inner boxes, the bar's
        recording chip, the Spotify panel) is a local aesthetic choice and is
        hardcoded at its single use site instead.  The bar's module groups get
        their own radius (barRadius in the quickshell Theme).
      '';
      type = lib.types.int;
      default = 2;
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
      description = "Active color scheme: a key of `themes` (see theme.nix).";
      type = lib.types.str;
      default = "nord";
    };
  };
}
