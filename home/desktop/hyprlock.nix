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
  # (Theme.glassTint / glassRim), so the lock screen reads as the desktop.
  glass = "rgba(140, 173, 189, 0.26)";
  glassStrong = "rgba(140, 173, 189, 0.38)";
  rim = "rgba(255, 255, 255, 0.55)";
  white = "rgba(255, 255, 255, 0.95)";
  dim = "rgba(255, 255, 255, 0.70)";
  barH = 27; # matches the shell's barHeight

  # Nerd Font glyphs (Nix strings have no \u escapes; JSON does).
  glyph = cp: builtins.fromJSON "\"\\u${cp}\"";
  lockGlyph = glyph "f023";
  userGlyph = glyph "f007";
  plugGlyph = glyph "f1e6";
  # Surrogate pairs for the supplementary-plane battery icons.
  batGlyph = builtins.fromJSON "\"\\udb80\\udc79\""; # nf-md-battery
  chargeGlyph = builtins.fromJSON "\"\\udb80\\udc84\""; # nf-md-battery_charging
  edge = 6; # matches Theme.frameEdge

  batteryScript = pkgs.writeShellScript "lock-battery" ''
    cap=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null) || exit 0
    st=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)
    case "$st" in Charging) icon="${chargeGlyph}" ;; Full|"Not charging") icon="${plugGlyph}" ;; *) icon="${batGlyph}" ;; esac
    echo "$icon $cap%"
  '';

  # Screen-wide glass strip (the frame's bar / rims).
  strip = size: position: valign: halign: {
    monitor = "";
    inherit size position valign halign;
    color = glass;
    rounding = 0;
    border_size = 0;
  };

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
  # Lock screen that looks like the desktop: blurred lagoon wallpaper, the
  # glass frame (top bar + thin rims around a rounded hairline), and a
  # frosted panel in the middle with avatar, name and password.
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

      shape = [
        # ── frame ─────────────────────────────────────────────────────
        (strip "1920, ${toString barH}" "0, 0" "top" "center")
        (strip "${toString edge}, 1080" "0, 0" "center" "left")
        (strip "${toString edge}, 1080" "0, 0" "center" "right")
        (strip "1920, ${toString edge}" "0, 0" "bottom" "center")
        # Rounded hairline around the "window area", like the shell's rim.
        {
          monitor = "";
          size = "${toString (1920 - 2 * edge)}, ${toString (1080 - barH - edge)}";
          position = "0, ${toString ((edge - barH) / 2)}";
          halign = "center";
          valign = "center";
          color = "rgba(0, 0, 0, 0)";
          rounding = 16;
          border_size = 1;
          border_color = rim;
        }

        # ── centre panel ──────────────────────────────────────────────
        {
          monitor = "";
          size = "380, 330";
          position = "0, 0";
          halign = "center";
          valign = "center";
          color = glass;
          rounding = 28;
          border_size = 1;
          border_color = rim;
          shadow_passes = 2;
          shadow_size = 16;
          shadow_color = "rgba(0, 0, 0, 0.22)";
        }
        # Avatar circle.
        {
          monitor = "";
          size = "92, 92";
          position = "0, 80";
          halign = "center";
          valign = "center";
          color = glassStrong;
          rounding = -1;
          border_size = 1;
          border_color = rim;
        }
      ];

      label = [
        # ── bar ───────────────────────────────────────────────────────
        {
          monitor = "";
          text = "${lockGlyph}  locked";
          color = dim;
          font_size = 12;
          font_family = vars.font.name;
          position = "${toString (edge + 12)}, -5";
          halign = "left";
          valign = "top";
        }
        {
          monitor = "";
          text = "cmd[update:1000] date +'%H:%M   ·   %a %d %b'";
          color = white;
          font_size = 12;
          font_family = vars.font.name;
          position = "0, -5";
          halign = "center";
          valign = "top";
        }
        {
          monitor = "";
          text = "cmd[update:30000] ${batteryScript}";
          color = dim;
          font_size = 12;
          font_family = vars.font.name;
          position = "-${toString (edge + 12)}, -5";
          halign = "right";
          valign = "top";
        }

        # ── panel ─────────────────────────────────────────────────────
        {
          monitor = "";
          text = userGlyph;
          color = white;
          font_size = 34;
          font_family = vars.font.name;
          position = "0, 80";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "$USER";
          color = white;
          font_size = 17;
          font_family = "${vars.font.name} Bold";
          position = "0, 8";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "cmd[update:60000] date +'%A, %d %B'";
          color = "rgb(${colors.base0C})";
          font_size = 11;
          font_family = vars.font.name;
          position = "0, -18";
          halign = "center";
          valign = "center";
        }
        # Now playing, at the bottom of the screen.
        {
          monitor = "";
          text = "cmd[update:2000] ${spotifyScript}";
          color = dim;
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
          size = "300, 46";
          position = "0, -80";
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
        }
      ];
    };
  };
}
