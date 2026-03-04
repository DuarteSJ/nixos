{
  config,
  pkgs,
  ...
}: let
  themeName = config.colorScheme.slug or "nord";
  laptopMonitor = config.monitors.laptop;
  externalMonitors = builtins.filter (m: m.enabled) config.monitors.external;

  laptopOrientation = if laptopMonitor.orientation == "vertical" then "vertical" else "horizontal";

  wallpapersDir = "${config.home.homeDirectory}/Pictures/wallpapers/${themeName}";
  defaultLaptopWallpaper = "${wallpapersDir}/${laptopOrientation}";

  getOrientationDir = monitor:
    if monitor.orientation == "vertical" then "vertical" else "horizontal";
in {
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      preload = [];
      wallpaper = [];
    };
  };

  systemd.user.services.hyprpaper-init = {
    Unit = {
      Description = "Initialize hyprpaper wallpapers";
      # Use hyprland-session.target so Hyprland is actually ready
      After = [ "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = let
        initScript = pkgs.writeShellScript "hyprpaper-init" ''
          # Wait for hyprpaper to be ready by polling hyprctl
          for i in $(seq 1 20); do
            if hyprctl hyprpaper listloaded >/dev/null 2>&1; then
              break
            fi
            sleep 0.5
          done

          # Set laptop wallpaper
          laptop_wp=$(${pkgs.findutils}/bin/find "${defaultLaptopWallpaper}" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) | ${pkgs.coreutils}/bin/sort -V | ${pkgs.coreutils}/bin/head -n1)
          if [[ -n "$laptop_wp" ]]; then
            hyprctl hyprpaper preload "$laptop_wp"
            hyprctl hyprpaper wallpaper "${laptopMonitor.name},$laptop_wp"
          fi

          # Set wallpapers for all external monitors
          ${builtins.concatStringsSep "\n" (map (m: let
            orientationDir = getOrientationDir m;
            wallpaperDir = "${wallpapersDir}/${orientationDir}";
          in ''
            external_wp=$(${pkgs.findutils}/bin/find "${wallpaperDir}" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) | ${pkgs.coreutils}/bin/sort -V | ${pkgs.coreutils}/bin/head -n1)
            if [[ -n "$external_wp" ]]; then
              hyprctl hyprpaper preload "$external_wp"
              hyprctl hyprpaper wallpaper "${m.name},$external_wp"
            fi
          '') externalMonitors)}
        '';
      in "${initScript}";
      RemainAfterExit = true;
    };

    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };
}
