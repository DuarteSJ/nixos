{
  config,
  pkgs,
  ...
}: let
  themeName = config.colorScheme.slug or "nord";
  externalMonitor = config.monitors.external;
  laptopMonitor = config.monitors.laptop;
  
  # Determine orientation subdirectories
  externalOrientation = if externalMonitor.orientation == "vertical" then "vertical" else "horizontal";
  laptopOrientation = if laptopMonitor.orientation == "vertical" then "vertical" else "horizontal";
  
  # Default wallpapers (first one from each orientation directory)
  wallpapersDir = "${config.home.homeDirectory}/Pictures/wallpapers/${themeName}";
  defaultExternalWallpaper = "${wallpapersDir}/${externalOrientation}";
  defaultLaptopWallpaper = "${wallpapersDir}/${laptopOrientation}";
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
          # Find first wallpaper in each orientation directory
          external_wp=$(${pkgs.findutils}/bin/find "${defaultExternalWallpaper}" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) | ${pkgs.coreutils}/bin/sort -V | ${pkgs.coreutils}/bin/head -n1)
          laptop_wp=$(${pkgs.findutils}/bin/find "${defaultLaptopWallpaper}" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) | ${pkgs.coreutils}/bin/sort -V | ${pkgs.coreutils}/bin/head -n1)
          
          # Set wallpapers if found
          if [[ -n "$external_wp" ]]; then
            ${pkgs.hyprland}/bin/hyprctl hyprpaper preload "$external_wp"
            ${pkgs.hyprland}/bin/hyprctl hyprpaper wallpaper "${externalMonitor.name},$external_wp"
          fi
          
          if [[ -n "$laptop_wp" ]]; then
            ${pkgs.hyprland}/bin/hyprctl hyprpaper preload "$laptop_wp"
            ${pkgs.hyprland}/bin/hyprctl hyprpaper wallpaper "${laptopMonitor.name},$laptop_wp"
          fi
        '';
      in "${initScript}";
      RemainAfterExit = true;
    };
    
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
