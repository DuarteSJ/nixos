{
  config,
  pkgs,
  ...
}: let
  themeName = config.colorScheme.slug or "nord";
  laptopMonitor = config.monitors.laptop;
  externalMonitors = builtins.filter (m: m.enabled) config.monitors.external;
  
  # Determine orientation subdirectories
  laptopOrientation = if laptopMonitor.orientation == "vertical" then "vertical" else "horizontal";
  
  # Default wallpapers directory
  wallpapersDir = "${config.home.homeDirectory}/Pictures/wallpapers/${themeName}";
  defaultLaptopWallpaper = "${wallpapersDir}/${laptopOrientation}";
  
  # Helper to get orientation directory for a monitor
  getOrientationDir = monitor: 
    if monitor.orientation == "vertical" then "vertical" else "horizontal";
in {
  services.hyprpaper = {
    enable = true;
    settings = {
      # Enable IPC for dynamic wallpaper switching via hyprctl
      ipc = "on";
      
      # Disable splash text
      splash = false;
      
      # Don't preload wallpapers at startup - we'll do it dynamically with switch-bg
      # This saves memory and allows for flexible wallpaper management
      preload = [];
      
      # No default wallpapers set - switch-bg will handle initial setup
      wallpaper = [];
    };
  };
  
  # Add a systemd service to set initial wallpapers on login
  systemd.user.services.hyprpaper-init = {
    Unit = {
      Description = "Initialize hyprpaper wallpapers";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    
    Service = {
      Type = "oneshot";
      ExecStart = let
        initScript = pkgs.writeShellScript "hyprpaper-init" ''
          sleep 2  # Wait for Hyprland to be fully ready
          
          # Set laptop wallpaper
          laptop_wp=$(${pkgs.findutils}/bin/find "${defaultLaptopWallpaper}" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) | ${pkgs.coreutils}/bin/sort -V | ${pkgs.coreutils}/bin/head -n1)
          if [[ -n "$laptop_wp" ]]; then
            ${pkgs.hyprland}/bin/hyprctl hyprpaper preload "$laptop_wp"
            ${pkgs.hyprland}/bin/hyprctl hyprpaper wallpaper "${laptopMonitor.name},$laptop_wp"
          fi
          
          # Set wallpapers for all external monitors
          ${builtins.concatStringsSep "\n" (map (m: let
            orientationDir = getOrientationDir m;
            wallpaperDir = "${wallpapersDir}/${orientationDir}";
          in ''
            external_wp=$(${pkgs.findutils}/bin/find "${wallpaperDir}" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) | ${pkgs.coreutils}/bin/sort -V | ${pkgs.coreutils}/bin/head -n1)
            if [[ -n "$external_wp" ]]; then
              ${pkgs.hyprland}/bin/hyprctl hyprpaper preload "$external_wp"
              ${pkgs.hyprland}/bin/hyprctl hyprpaper wallpaper "${m.name},$external_wp"
            fi
          '') externalMonitors)}
        '';
      in "${initScript}";
      RemainAfterExit = true;
    };
    
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
