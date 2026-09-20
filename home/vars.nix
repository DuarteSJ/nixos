{
  lib,
  config,
  ...
}: {
  options.vars = {
    rounding = lib.mkOption {
      description = ''
        Surface corner radius: hyprland windows, dunst notifications, the
        rofi window.  Deliberately NOT hardcoded -- the
        hyprland value alone is read from four places that must agree (the
        static decoration block plus prodToggle, incGaps and decGaps in
        lua-actions.nix).  If they drift, toggling focus mode or nudging gaps
        silently leaves windows at a different radius than you logged in with.

        Anything nested INSIDE a surface (rofi's inner boxes, the waybar
        recording chip, the Spotify panel) is a local aesthetic choice and is
        hardcoded at its single use site instead.  Waybar's module groups get
        their own knob, `waybarRounding` below.
      '';
      type = lib.types.int;
      default = 0;
    };

    waybarRounding = lib.mkOption {
      description = ''
        Corner radius for waybar's module groups.  Separate from `rounding`
        because the bar is flush against the top, left and right screen edges,
        so only the corners that sit on no edge are rounded at all -- and those
        want a different weight than a free-floating tiled window.

        Applied per group in home/shell/waybar.nix:
          .modules-left    bottom-right only   (top + left edges are walls)
          .modules-center  both bottom corners (only the top edge is a wall)
          .modules-right   bottom-left only    (top + right edges are walls)
      '';
      type = lib.types.int;
      default = 8;
    };

    gapsOuter = lib.mkOption {
      description = "Outer gap. Matches waybar's bar margin so windows and the bar sit the same distance from the screen edge.";
      type = lib.types.int;
      default = 8;
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
          sizeStr = lib.mkOption {
            type = lib.types.str;
            default = "12.5";
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
            default = "${config.home.homeDirectory}/notes";
          };
          wallpapers = lib.mkOption {
            type = lib.types.str;
            default = "${config.home.homeDirectory}/Pictures/wallpapers";
          };
        };
      };
    };
  };
}
