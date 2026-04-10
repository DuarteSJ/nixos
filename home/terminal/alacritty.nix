{config, ...}: let
  inherit (config.colorScheme) palette;
  inherit (config) vars;
in {
  programs.alacritty = {
    enable = true;
    settings = {
      terminal.shell.program = "/run/current-system/sw/bin/zsh";
      font = {
        inherit (vars.font) size;
        normal = {
          family = vars.font.name;
          style = "Regular";
        };
        bold = {
          family = vars.font.name;
          style = "Bold";
        };
        bold_italic = {
          family = vars.font.name;
          style = "Bold Italic";
        };
        italic = {
          family = vars.font.name;
          style = "Italic";
        };
      };
      window = {
        opacity = 1;
        padding = {
          x = 15;
          y = 15;
        };
        dimensions = {
          columns = 50;
          lines = 12;
        };
      };
      cursor.style = {
        shape = "Underline";
        blinking = "Always";
      };
      keyboard.bindings = [
        {
          key = "Q";
          mods = "Super|Shift";
          action = "SpawnNewInstance";
        }
      ];
      colors = with palette; {
        primary = {
          background = "#${base00}";
          foreground = "#${base05}";
        };
        normal = {
          black = "#${base01}";
          red = "#${base08}";
          green = "#${base0B}";
          yellow = "#${base0A}";
          blue = "#${base0D}";
          magenta = "#${base0E}";
          cyan = "#${base0C}";
          white = "#${base05}";
        };
        bright = {
          black = "#${base03}";
          red = "#${base08}";
          green = "#${base0B}";
          yellow = "#${base0A}";
          blue = "#${base0D}";
          magenta = "#${base0E}";
          cyan = "#${base0C}";
          white = "#${base07}";
        };
      };
    };
  };
}
