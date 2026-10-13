{
  config,
  pkgs,
  ...
}: let
  colors = config.colorScheme.palette;
  inherit (config) vars;

  # Same image the desktop uses, straight from its derivation.
  wallpaper = pkgs.callPackage ./wallpaper-lagoon/package.nix {};

  # Frosted-glass tokens (match the quickshell frame / notifications).
  glass = "rgba(140, 173, 189, 0.20)";
  rim = "rgba(255, 255, 255, 0.45)";
  white = "rgba(255, 255, 255, 0.95)";

  spotifyScript = pkgs.writeShellScript "spotify-status" ''
    # Get metadata
    artist=$(${pkgs.playerctl}/bin/playerctl metadata artist 2>/dev/null || echo "No artist")
    title=$(${pkgs.playerctl}/bin/playerctl metadata title 2>/dev/null || echo "No track")
    status=$(${pkgs.playerctl}/bin/playerctl status 2>/dev/null || echo "Stopped")

    # Display only if music is playing
    if [ "$status" != "Stopped" ]; then
      echo "♫ ''${artist}    ''${title} ♫"
    fi
  '';
in {
  # Lock screen in the liquid-glass style: the lagoon wallpaper heavily
  # blurred, a frosted card holding a big clock and the date, and a frosted
  # pill for the password.
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        ignore_empty_input = true;
      };

      animations = {
        enabled = true;
        bezier = ["glass, 0.16, 1, 0.3, 1"];
        animation = [
          "fadeIn, 1, 6, glass"
          "fadeOut, 1, 5, glass"
          "inputFieldDots, 1, 3, glass"
        ];
      };

      background = [
        {
          monitor = "";
          path = "${wallpaper}";
          blur_passes = 3;
          blur_size = 8;
          noise = 0.015;
          brightness = 0.85;
          vibrancy = 0.25;
        }
      ];

      # The glass card behind the clock.
      shape = [
        {
          monitor = "";
          size = "560, 300";
          color = glass;
          rounding = 32;
          border_size = 1;
          border_color = rim;
          shadow_passes = 2;
          shadow_size = 14;
          shadow_color = "rgba(0, 0, 0, 0.25)";
          position = "0, 110";
          halign = "center";
          valign = "center";
        }
      ];

      label = [
        # TIME
        {
          monitor = "";
          text = "cmd[update:1000] date +%H:%M";
          color = white;
          font_size = 120;
          font_family = "${vars.font.name} ExtraBold";
          shadow_passes = 2;
          shadow_size = 6;
          shadow_color = "rgba(0, 0, 0, 0.25)";
          position = "0, 140";
          halign = "center";
          valign = "center";
        }
        # DATE
        {
          monitor = "";
          text = "cmd[update:60000] date +'%A, %d %B'";
          color = "rgb(${colors.base0C})";
          font_size = 20;
          font_family = vars.font.name;
          position = "0, 25";
          halign = "center";
          valign = "center";
        }
        # NOW PLAYING
        {
          monitor = "";
          text = "cmd[update:2000] ${spotifyScript}";
          color = "rgba(255, 255, 255, 0.7)";
          font_size = 13;
          font_family = vars.font.name;
          position = "0, 40";
          halign = "center";
          valign = "bottom";
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "340, 56";
          rounding = -1;
          outline_thickness = 1;
          outer_color = rim;
          inner_color = glass;
          font_color = white;
          font_family = vars.font.name;
          check_color = "rgb(${colors.base0C})";
          fail_color = "rgb(${colors.base08})";
          capslock_color = "rgb(${colors.base0A})";
          dots_size = 0.22;
          dots_spacing = 0.4;
          dots_center = true;
          fade_on_empty = false;
          placeholder_text = "<span foreground='##ffffffaa'>password</span>";
          fail_text = "<i>$FAIL</i>";
          hide_input = false;
          shadow_passes = 2;
          shadow_size = 10;
          shadow_color = "rgba(0, 0, 0, 0.2)";
          position = "0, -170";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
