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
          path = "/home/duartesj/Pictures/lock-screen/snow-mountain.jpg";
        }
        {
          monitor = "";
          zindex = 1;
          keep_aspect_ratio = true;
          rounding = 0;
          border_size = 0;
          path = "/home/duartesj/Pictures/lock-screen/snow-mountain-overlay.png";
        }
      ];

      # GENERAL
      general = {
        no_fade_in = true;
        no_fade_out = true;
        hide_cursor = true;
        grace = 0;
        disable_loading_bar = true;
      };

      # INPUT FIELD
      input-field = [
        {
          monitor = "";
          size = "250, 60";
          outline_thickness = 2;
          dots_size = 0.2;
          dots_spacing = 0.35;
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
          zindex = 1;
        }
      ];

      # LABELS
      label = [
        # DATE
        {
          monitor = "";
          text = "cmd[update:1000] echo \"$(date +\"%A, %d %b\")\"";
          color = "rgba(255, 255, 255, 0.9)";
          font_size = 60;
          font_family = "Adwaita Sans, thin";
          position = "0, 375";
          halign = "center";
          valign = "center";
        }
        # TIME - HOURS
        {
          monitor = "";
          text = "cmd[update:1000] echo -e \"$(date +\"%H\")\"";
          color = "rgba(172, 166, 180, 1)";
          font_size = 120;
          font_family = "Adwaita Sans, Heavy";
          position = "-145, 90";
          halign = "center";
          valign = "center";
        }
        # TIME - MINUTES
        {
          monitor = "";
          text = "cmd[update:1000] echo -e \"$(date +\"%M\")\"";
          color = "rgba(255, 255, 255, 1)";
          font_size = 120;
          font_family = "Adwaita Sans, Heavy";
          position = "145, 90";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
