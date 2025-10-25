{ config, ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      terminal.shell.program = "/run/current-system/sw/bin/zsh";
      font = {
        size = 12.5;
        normal = {
          family = "JetBrains Mono Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "JetBrains Mono Nerd Font";
          style = "Bold";
        };
        bold_italic = {
          family = "JetBrains Mono Nerd Font";
          style = "Bold Italic";
        };
        italic = {
          family = "JetBrains Mono Nerd Font";
          style = "Italic";
        };
      };
      window = {
        opacity = 1;
        padding = { x = 15; y = 15; };
        dimensions = { columns = 50; lines = 12; };
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
      colors = with config.colorScheme.palette; {
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
