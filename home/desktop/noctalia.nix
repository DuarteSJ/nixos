{
  config,
  inputs,
  system,
  ...
}: let
  inherit (config) vars;
  walls = "${config.home.homeDirectory}/Pictures/wallpapers/";

in {
  imports = [inputs.noctalia.homeModules.default];

  # Stock Noctalia shell (v5). Declarative config → ~/.config/noctalia/config.toml
  # (snake_case schema; see noctalia example.toml). settings.json stays writable,
  # so anything NOT pinned here can still be tweaked live in the GUI.
  programs.noctalia = {
    enable = true;
    package = inputs.noctalia.packages.${system}.default;
    # Autostarted via Hyprland exec-once (see hyprland/default.nix), NOT systemd:
    # the systemd user service lacks WAYLAND_DISPLAY + a logind seat, so it
    # crash-loops on "failed to connect to Wayland display" and brightness fails.
    systemd.enable = false;

    settings = {
      shell = {
        font_family = vars.font.name;
        ui_scale = 1.0;
        corner_radius_scale = 1.0;
      };

      theme = {
        mode = "auto";
        source = "builtin";
        builtin = "Nord";
      };

      wallpaper = {
        enabled = true;
        directory = walls;
        fill_mode = "crop";
        default.path = "${walls}/nord/horizontal/minimal-mountain.png";
      };

      # Floating, capsule (pill) bar — inspired by ctknightdev/nixos.
      bar.main = {
        position = "top";
        capsule = true;
        start = ["launcher" "clock" "system-monitor" "active-window" "media"];
        center = ["workspaces"];
        end = ["tray" "notifications" "network" "bluetooth" "volume" "brightness" "battery" "control-center" "session"];
      };

      widget.clock = {
        format = "{:%H:%M  %a, %b %d}";
        tooltip_format = "{:%A, %B %d, %Y}";
      };
    };
  };
}
