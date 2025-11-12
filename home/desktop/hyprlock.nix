{
  config,
  pkgs,
  ...
}: let
  colors = config.colorScheme.palette;

  spotifyScript = pkgs.writeShellScript "spotify-status" ''
    # Get metadata
    artist=$(playerctl metadata artist 2>/dev/null || echo "No artist")
    title=$(playerctl metadata title 2>/dev/null || echo "No track")
    status=$(playerctl status 2>/dev/null || echo "Stopped")

    # Display only if music is playing
    if [ "$status" != "Stopped" ]; then
      echo "♫ ''${artist}    ''${title} ♫"
    fi
  '';
in {
  programs.hyprlock = {
    enable = true;
    settings = {
      # GENERAL
      general = {
        hide_cursor = false;
        grace = 0;
      };

      # BACKGROUND
      background = [
        {
          monitor = "";
          path = "~/Pictures/lock-screen/minimal-mountain.png";
        }
      ];

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
          position = "0, -400";
          halign = "center";
          valign = "center";
        }
      ];

      # LABELS
      label = [
        # DATE
        {
          monitor = "";
          text = "cmd[update:1000] date +\"%A, %d %B\" | sed 's/\\b\\(.\\)/\\U\\1/g'";
          color = "rgb(${colors.base05})";
          font_size = 22;
          font_family = "JetBrains Mono";
          position = "0, -100";
          halign = "center";
          valign = "center";
        }
        # TIME
        {
          monitor = "";
          text = "cmd[update:1000] echo \"$(date +\"%H:%M\")\"";
          color = "rgb(${colors.base05})";
          font_size = 125;
          font_family = "JetBrains Mono Extrabold";
          position = "0, 50";
          halign = "center";
          valign = "center";
        }
        # SPOTIFY NOW PLAYING
        {
          monitor = "";
          text = "cmd[update:2000] ${spotifyScript}";
          color = "rgb(${colors.base05})";
          font_size = 14;
          font_family = "JetBrains Mono";
          position = "0, -515";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
