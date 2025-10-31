{
  config,
  pkgs,
  ...
}: {
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        source = "nixos";
        padding = {
          right = 3;
          top = 1;
        };
      };
      display = {
        separator = "  ";
        color = {
          keys = "blue";
          title = "bold_cyan";
        };
      };
      modules = [
        {
          type = "title";
          format = "{user-name-colored}@{host-name-colored}";
        }
        {
          type = "separator";
          string = "─────────────────────────────";
        }
        {
          type = "os";
          key = " ";
          keyColor = "blue";
        }
        {
          type = "kernel";
          key = " ";
          keyColor = "cyan";
        }
        {
          type = "packages";
          key = "󰏖 ";
          keyColor = "magenta";
        }
        {
          type = "shell";
          key = " ";
          keyColor = "green";
        }
        {
          type = "wm";
          key = " ";
          keyColor = "yellow";
        }
        {
          type = "terminal";
          key = " ";
          keyColor = "blue";
        }
        "break"
        {
          type = "cpu";
          key = "󰻠 ";
          keyColor = "red";
        }
        {
          type = "gpu";
          key = "󰍛 ";
          keyColor = "magenta";
        }
        {
          type = "memory";
          key = "󰑭 ";
          keyColor = "yellow";
        }
        {
          type = "disk";
          key = "󰋊 ";
          keyColor = "cyan";
        }
        {
          type = "uptime";
          key = "󰥔 ";
          keyColor = "green";
        }
        {
          type = "separator";
          string = "─────────────────────────────";
        }
        {
          type = "colors";
          symbol = "circle";
        }
      ];
    };
  };
}
