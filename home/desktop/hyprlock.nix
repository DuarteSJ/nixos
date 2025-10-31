{config, ...}: let
  colors = config.colorScheme.palette;
in {
  programs.hyprlock = {
    enable = true;
    settings = {
      # BACKGROUND
      background = [
        {
          monitor = "";
          path = "screenshot";
          blur_passes = 2;
          contrast = 1.0;
          brightness = 0.8;
          vibrancy = 0.2;
          vibrancy_darkness = 0.2;
        }
      ];
      # GENERAL
      general = {
        hide_cursor = false;
        grace = 0;
      };

      # INPUT FIELD
      input-field = [
        {
          monitor = "";
          size = "250, 60";
          outline_thickness = 2;
          dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
          dots_spacing = 0.35; # Scale of dots' absolute size, 0.0 - 1.0
          dots_center = true;
          outer_color = "rgba(0, 0, 0, 0)";
          inner_color = "rgba(0, 0, 0, 0.2)";
          font_color = "rgb(${colors.base05})";
          fade_on_empty = false;
          rounding = -1;
          check_color = "rgb(${colors.base09})";
          placeholder_text = "Input Password...";
          hide_input = false;
          position = "0, -200";
          halign = "center";
          valign = "center";
        }
      ];

      # LABELS
      label = [
        # DATE
        {
          monitor = "";
          text = "cmd[update:1000] echo \"$(date +\"%A, %B %d\")\"";
          color = "rgb(${colors.base05})";
          font_size = 22;
          font_family = "JetBrains Mono";
          position = "0, 300";
          halign = "center";
          valign = "center";
        }
        # TIME
        {
          monitor = "";
          text = "cmd[update:1000] echo \"$(date +\"%H:%M\")\"";
          color = "rgb(${colors.base05})";
          font_size = 95;
          font_family = "JetBrains Mono Extrabold";
          position = "0, 200";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
