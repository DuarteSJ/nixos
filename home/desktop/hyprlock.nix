{
  config,
  lib,
  pkgs,
  ...
}: let
  colors = config.colorScheme.palette;
  inherit (config) vars;

  # One playerctl call per tick (this runs every 2 s while locked).  Title
  # last, so a "|" in it survives the split.  No player at all -> empty
  # status, treated like Stopped: print nothing.
  spotifyScript = pkgs.writeShellScript "spotify-status" ''
    IFS='|' read -r status artist title < <(
      ${pkgs.playerctl}/bin/playerctl metadata \
        --format '{{status}}|{{artist}}|{{title}}' 2>/dev/null
    )

    if [ -n "$status" ] && [ "$status" != "Stopped" ]; then
      echo "♫ ''${artist:-No artist}    ''${title:-No track} ♫"
    fi
  '';
in {
  # Lock before every suspend (lid, session menu, `systemctl suspend`):
  # hypridle holds logind's sleep inhibitor and, with inhibit_sleep = 3,
  # releases it only once hyprlock has actually locked the session.
  services.hypridle = {
    enable = true;
    settings.general = {
      lock_cmd = "pidof hyprlock || ${lib.getExe config.programs.hyprlock.package}";
      before_sleep_cmd = "loginctl lock-session";
      inhibit_sleep = 3;
    };
  };

  programs.hyprlock = {
    enable = true;
    # Only non-defaults: widgets default to every monitor, centred.
    settings = {
      # BACKGROUND
      background = [
        {
          path = "~/Pictures/lock-screen/minimal-mountain.png";
        }
      ];

      # INPUT FIELD
      input-field = [
        {
          size = "250, 60";
          outline_thickness = 2;
          dots_size = 0.2;
          dots_spacing = 0.35;
          outer_color = "rgba(0, 0, 0, 0)";
          inner_color = "rgba(0, 0, 0, 0.2)";
          font_color = "rgb(${colors.base05})";
          fade_on_empty = false;
          check_color = "rgb(${colors.base09})";
          placeholder_text = "Input Password...";
          position = "0, -400";
        }
      ];

      # LABELS
      label = [
        # DATE
        {
          text = "cmd[update:1000] date +\"%A, %d %B\" | sed 's/\\b\\(.\\)/\\U\\1/g'";
          color = "rgb(${colors.base05})";
          font_size = 22;
          font_family = vars.font.name;
          position = "0, -100";
        }
        # TIME
        {
          text = "$TIME"; # built-in 24h HH:MM, no fork
          color = "rgb(${colors.base05})";
          font_size = 125;
          font_family = "JetBrains Mono Extrabold";
          position = "0, 50";
        }
        # SPOTIFY NOW PLAYING
        {
          text = "cmd[update:2000] ${spotifyScript}";
          color = "rgb(${colors.base05})";
          font_size = 14;
          font_family = vars.font.name;
          position = "0, -515";
        }
      ];
    };
  };
}
