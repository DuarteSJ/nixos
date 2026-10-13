{
  config,
  pkgs,
  ...
}: let
  inherit (config) vars;

  # Glass terminal: a light frosted-teal body at partial opacity, so
  # Hyprland's blur of whatever is behind shows through, with bright, soft
  # ANSI colours that stay readable on it.  Deliberately its own set rather
  # than the palette's dark base00, which made the terminal a heavy slab.
  glass = {
    background = "#1d3b48";
    foreground = "#eef7f9";
    normal = {
      black = "#2f4f5c";
      red = "#ff8f94";
      green = "#9fe6b8";
      yellow = "#f6df91";
      blue = "#8fd0f8";
      magenta = "#cbbcf8";
      cyan = "#82ece8";
      white = "#dbe9ee";
    };
    bright = {
      black = "#6f909c";
      red = "#ffb0b3";
      green = "#bdf2cf";
      yellow = "#fbecb5";
      blue = "#b5e1fb";
      magenta = "#ddd3fb";
      cyan = "#aaf4f1";
      white = "#ffffff";
    };
  };
in {
  programs.alacritty = {
    enable = true;
    settings = {
      terminal.shell.program = "${pkgs.zsh}/bin/zsh";
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
        opacity = 0.72;
        padding = {
          x = 15;
          y = 15;
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
      colors = {
        primary = {inherit (glass) background foreground;};
        inherit (glass) normal bright;
        selection = {
          background = "#3f6f80";
          text = "CellForeground";
        };
        cursor = {
          cursor = "#82ece8";
          text = "#1d3b48";
        };
      };
    };
  };
}
