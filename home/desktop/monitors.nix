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
      orientation = lib.mkOption {
        type = lib.types.enum ["horizontal" "vertical"];
        default = "horizontal";
        description = "Monitor orientation.";
      };
      enabled = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether this monitor is enabled.";
      };
      workspaces = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = [];
        description = "List of workspace numbers assigned to this monitor.";
      };
    };
  };
in {
  options.monitors = {
    laptop = lib.mkOption {
      type = monitorType;
      description = "Laptop monitor configuration";
    };
    external = lib.mkOption {
      type = lib.types.listOf monitorType;
      default = [];
      description = "List of external monitor configurations";
    };
  };
  
  config.monitors = {
    laptop = {
      name = "eDP-1";
      mode = "1920x1200@59.95";
      position = "0x0";
      enabled = false;
      workspaces = [5];
    };
    external = [
      {
        name = "DP-3";
        mode = "1920x1080@119.98";
        position = "1920x0";
        enabled = true;
        # orientation = "vertical";
        workspaces = [1 2 3 4];
      }
    ];
  };
}
