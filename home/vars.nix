{
  lib,
  config,
  ...
}: {
  options.vars = {
    rounding = lib.mkOption {
      description = ''
        Surface corner radius: hyprland windows, notifications, the
        launcher.  Deliberately NOT hardcoded -- the
        hyprland value alone is read from four places that must agree (the
        static decoration block plus prodToggle, incGaps and decGaps in
        lua-actions.nix).  If they drift, toggling focus mode or nudging gaps
        silently leaves windows at a different radius than you logged in with.

        Anything nested INSIDE a surface (the launcher's inner boxes, the bar's
        recording chip, the Spotify panel) is a local aesthetic choice and is
        hardcoded at its single use site instead.  The bar's module groups get
        their own knob, `barRounding` below.
      '';
      type = lib.types.int;
      default = 2;
    };

    barRounding = lib.mkOption {
      description = ''
        Corner radius for the bar's module groups.  Separate from `rounding`
        because the bar is flush against the top, left and right screen edges,
        so only the corners that sit on no edge are rounded at all -- and those
        want a different weight than a free-floating tiled window.

        Applied per group in home/shell/quickshell/qml/Group.qml:
          left    bottom-right only   (top + left edges are walls)
          centre  both bottom corners (only the top edge is a wall)
          right   bottom-left only    (top + right edges are walls)
      '';
      type = lib.types.int;
      default = 8;
    };

    gapsOuter = lib.mkOption {
      description = "Outer gap. Matches the bar's margin so windows and the bar sit the same distance from the screen edge.";
      type = lib.types.int;
      default = 8;
    };

    gapsInner = lib.mkOption {
      description = "Inner gap. Derived as half the outer gap; single source for the gaps/2 relationship reused across hyprland and the bar.";
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
      default = "lagoon";
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
