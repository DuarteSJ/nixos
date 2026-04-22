{lib, ...}: let
  externalType = lib.types.submodule {
    options = {
      description = lib.mkOption {
        type = lib.types.str;
        description = ''
          EDID description as reported by `hyprctl monitors` in the
          `description` field. Matches the monitor regardless of which
          port it's plugged into.  Example:
            "Dell Inc. DELL U2720Q ABCD1234"
        '';
      };
      mode = lib.mkOption {
        type = lib.types.str;
        default = "preferred";
        description = "Resolution and refresh rate (e.g. 1920x1080@120). 'preferred' lets Hyprland pick.";
      };
      position = lib.mkOption {
        type = lib.types.str;
        default = "auto";
        description = "Position in the global canvas (e.g. 1920x0). 'auto' lets Hyprland place it.";
      };
      scale = lib.mkOption {
        type = lib.types.str;
        default = "1";
      };
      transform = lib.mkOption {
        type = lib.types.int;
        default = 0;
        description = "Hyprland transform value (0 = normal, 1 = 90°, 2 = 180°, 3 = 270°).";
      };
    };
  };

  laptopType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Connector name — the laptop panel doesn't move between ports.";
      };
      mode = lib.mkOption {
        type = lib.types.str;
        default = "preferred";
      };
      position = lib.mkOption {
        type = lib.types.str;
        default = "0x0";
      };
      scale = lib.mkOption {
        type = lib.types.str;
        default = "1";
      };
      transform = lib.mkOption {
        type = lib.types.int;
        default = 0;
      };
    };
  };
in {
  options.monitors = {
    laptop = lib.mkOption {
      type = laptopType;
      description = "The built-in laptop panel.";
    };

    externals = lib.mkOption {
      type = lib.types.listOf externalType;
      default = [];
      description = ''
        Known external monitors, identified by EDID description so the
        same spec applies regardless of which port they're plugged
        into.  Anything not listed here falls through to Hyprland's
        catch-all rule (preferred mode, auto position).
      '';
    };

    workspaces = lib.mkOption {
      type = lib.types.listOf lib.types.int;
      default = [1 2 3 4 5];
      description = ''
        Workspaces the monitor-manager assigns to the primary monitor
        at runtime.  Primary is the first connected external (if any),
        otherwise the laptop.
      '';
    };

    preferExternal = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        When true, the monitor-manager disables the laptop panel while
        any external is connected and re-enables it when the last
        external is unplugged.
      '';
    };
  };

  config.monitors = {
    laptop = {
      name = "eDP-1";
      mode = "1920x1200@59.95";
    };

    # Fill in regularly-used externals here.  Run `hyprctl monitors`
    # while the monitor is connected and copy the `description` field
    # verbatim.  Example:
    #
    #   externals = [
    #     {
    #       description = "Dell Inc. DELL U2720Q ABCD1234";
    #       mode = "1920x1080@119.98";
    #       position = "1920x0";
    #     }
    #   ];
    externals = [];

    workspaces = [1 2 3 4];
    preferExternal = true;
  };
}
