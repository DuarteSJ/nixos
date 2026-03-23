{ lib, ... }: let

  monitorType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Monitor connector name as reported by Hyprland (e.g. DP-3, HDMI-A-1).";
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
        description = "Scaling factor.";
      };
      transform = lib.mkOption {
        type = lib.types.int;
        default = 0;
        description = "Hyprland transform value (0 = normal, 1 = 90°, 2 = 180°, 3 = 270°).";
      };
      workspaces = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = [];
        description = "Workspaces to pin to this monitor.";
      };
    };
  };

in {
  options.monitors = {

    laptop = lib.mkOption {
      type = monitorType;
      description = "The built-in laptop panel.";
    };

    external = lib.mkOption {
      type = lib.types.listOf monitorType;
      default = [];
      description = "Known external monitors.";
    };

    disableLaptopWhenExternal = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        When true, the monitor-manager script disables the laptop panel
        while at least one external monitor is connected, and re-enables
        it the moment the last external is unplugged. Handled entirely
        at runtime — no rebuild required.
      '';
    };

  };

  config.monitors = {

    disableLaptopWhenExternal = true;

    laptop = {
      name       = "eDP-1";
      mode       = "1920x1200@59.95";
      position   = "0x0";
      workspaces = [ 5 ];
    };

    external = [
      {
        name       = "DP-3";
        mode       = "1920x1080@119.98";
        position   = "1920x0";
        # transform  = 1;
        workspaces = [ 1 2 3 4 ];
      }
    ];

  };
}
