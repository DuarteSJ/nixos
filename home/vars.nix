{ lib, ... }:

{
  options.vars = {
    description = "Global variables used across the system.";
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
  };

  config.vars = {
    rounding = 2;
    gaps     = 4;
    font     = {
      name = "JetBrainsMono Nerd Font";
      size = 12.5;
    };
  };
}
