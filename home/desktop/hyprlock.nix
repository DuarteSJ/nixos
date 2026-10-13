{
  config,
  pkgs,
  ...
}: let
  colors = config.colorScheme.palette;
  inherit (config) vars;

  # Same image the desktop uses, straight from its derivation.
  wallpaper = pkgs.callPackage ./wallpaper-lagoon/package.nix {};

  # Frosted-glass tokens -- the same values as the quickshell frame
  # (Theme.glassTint / glassRim).
  glassStrong = "rgba(140, 173, 189, 0.38)";
  rim = "rgba(255, 255, 255, 0.55)";
  white = "rgba(255, 255, 255, 0.95)";

  spotifyScript = pkgs.writeShellScript "spotify-status" ''
    artist=$(${pkgs.playerctl}/bin/playerctl metadata artist 2>/dev/null || echo "No artist")
    title=$(${pkgs.playerctl}/bin/playerctl metadata title 2>/dev/null || echo "No track")
    status=$(${pkgs.playerctl}/bin/playerctl status 2>/dev/null || echo "Stopped")

    # Display only if music is playing
    if [ "$status" != "Stopped" ]; then
      echo "♫ ''${artist}    ''${title} ♫"
    fi
  '';
in {
  # The clock face (rounded, relaxed).  fontconfig so user-installed fonts
  # are visible to hyprlock.
  home.packages = [pkgs.quicksand];
  fonts.fontconfig.enable = true;

  # Lock screen: the lagoon wallpaper blurred, a big clock straight on it,
  # and a single frosted pill for the password.
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
          blur_size = 7;
          noise = 0.015;
          brightness = 0.9;
          vibrancy = 0.25;
        }
      ];

      label = [
        # TIME -- rounded and soft, not a glowing slab.
        {
          monitor = "";
          text = "cmd[update:1000] date +%H:%M";
          color = "rgba(236, 244, 247, 0.72)";
          font_size = 130;
          font_family = "Quicksand Medium";
          shadow_passes = 1;
          shadow_size = 4;
          shadow_color = "rgba(0, 0, 0, 0.15)";
          position = "0, 140";
          halign = "center";
          valign = "center";
        }
        # DATE
        {
          monitor = "";
          text = "cmd[update:60000] date +'%A, %d %B'";
          color = "rgba(236, 244, 247, 0.65)";
          font_size = 17;
          font_family = "Quicksand Medium";
          shadow_passes = 1;
          shadow_size = 3;
          shadow_color = "rgba(0, 0, 0, 0.15)";
          position = "0, 20";
          halign = "center";
          valign = "center";
        }
        # NOW PLAYING
        {
          monitor = "";
          text = "cmd[update:2000] ${spotifyScript}";
          color = "rgba(255, 255, 255, 0.7)";
          font_size = 12;
          font_family = vars.font.name;
          position = "0, 30";
          halign = "center";
          valign = "bottom";
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "320, 50";
          position = "0, -120";
          halign = "center";
          valign = "center";
          rounding = -1;
          outline_thickness = 1;
          outer_color = rim;
          inner_color = glassStrong;
          font_color = white;
          font_family = vars.font.name;
          check_color = "rgb(${colors.base0C})";
          fail_color = "rgb(${colors.base08})";
          capslock_color = "rgb(${colors.base0A})";
          dots_size = 0.2;
          dots_spacing = 0.4;
          dots_center = true;
          fade_on_empty = false;
          placeholder_text = "<span foreground='##ffffffaa'>password</span>";
          fail_text = "<i>$FAIL</i>";
          hide_input = false;
          shadow_passes = 2;
          shadow_size = 10;
          shadow_color = "rgba(0, 0, 0, 0.2)";
        }
      ];
    };
  };
}
