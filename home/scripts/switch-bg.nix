{
  config,
  pkgs,
  ...
}: let
  # monitors
  externalMonitor = config.monitors.external;
  laptopMonitor = config.monitors.laptop;
  themeName = config.colorScheme.slug or "nord";
in {
  home.packages = [
    (pkgs.writeShellScriptBin "switch-bg" ''
      set -euo pipefail
      cur_theme_name="${themeName}"
      wallpapers_dir="$HOME/Pictures/wallpapers/$cur_theme_name"

      # Check if wallpapers directory exists
      if [[ ! -d "$wallpapers_dir" ]]; then
          ${pkgs.dunst}/bin/dunstify -u critical "Background Error" "Directory '$wallpapers_dir' not found"
          exit 1
      fi

      # Determine orientation subdirectories
      external_orientation="${if externalMonitor.orientation == "vertical" then "vertical" else "horizontal"}"
      laptop_orientation="${if laptopMonitor.orientation == "vertical" then "vertical" else "horizontal"}"

      external_dir="$wallpapers_dir/$external_orientation"
      laptop_dir="$wallpapers_dir/$laptop_orientation"

      # Function to get wallpapers from a directory
      get_wallpapers() {
          local dir="$1"
          if [[ -d "$dir" ]]; then
              ${pkgs.findutils}/bin/find "$dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | ${pkgs.coreutils}/bin/sort -V
          fi
      }

      # Get wallpapers for each monitor
      mapfile -t external_wallpapers < <(get_wallpapers "$external_dir")
      mapfile -t laptop_wallpapers < <(get_wallpapers "$laptop_dir")

      # Fallback to root directory if orientation subdirs don't exist or are empty
      if [[ ''${#external_wallpapers[@]} -eq 0 && ''${#laptop_wallpapers[@]} -eq 0 ]]; then
          mapfile -t all_wallpapers < <(${pkgs.findutils}/bin/find "$wallpapers_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | ${pkgs.coreutils}/bin/sort -V)
          
          if [[ ''${#all_wallpapers[@]} -eq 0 ]]; then
              ${pkgs.dunst}/bin/dunstify -u critical "Background Error" "No image files found in '$wallpapers_dir'"
              exit 1
          fi
          
          # Use same wallpaper for both monitors
          external_wallpapers=("''${all_wallpapers[@]}")
          laptop_wallpapers=("''${all_wallpapers[@]}")
      fi

      # If one orientation is missing, use the other
      if [[ ''${#external_wallpapers[@]} -eq 0 ]]; then
          external_wallpapers=("''${laptop_wallpapers[@]}")
      fi
      if [[ ''${#laptop_wallpapers[@]} -eq 0 ]]; then
          laptop_wallpapers=("''${external_wallpapers[@]}")
      fi

      # Detect which monitor the active window is on
      active_monitor=$(${pkgs.hyprland}/bin/hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.focused == true) | .name')

      # Read current wallpapers from state file
      state_file="$HOME/.cache/wallpaper-state"
      ${pkgs.coreutils}/bin/mkdir -p "$HOME/.cache"
      ${pkgs.coreutils}/bin/touch "$state_file"

      external_index=0
      laptop_index=0

      if [[ -f "$state_file" ]]; then
          while IFS='=' read -r key value; do
              if [[ "$key" == "external_index" ]]; then
                  external_index="$value"
              elif [[ "$key" == "laptop_index" ]]; then
                  laptop_index="$value"
              fi
          done < "$state_file"
      fi

      # Calculate next indices based on which monitor is active
      if [[ "$active_monitor" == "${externalMonitor.name}" ]]; then
          external_index=$(( (external_index + 1) % ''${#external_wallpapers[@]} ))
          next_wallpaper="''${external_wallpapers[$external_index]}"
          monitor_name="${externalMonitor.name}"
          orientation="$external_orientation"
          total_count=''${#external_wallpapers[@]}
          current_num=$((external_index + 1))
      elif [[ "$active_monitor" == "${laptopMonitor.name}" ]]; then
          laptop_index=$(( (laptop_index + 1) % ''${#laptop_wallpapers[@]} ))
          next_wallpaper="''${laptop_wallpapers[$laptop_index]}"
          monitor_name="${laptopMonitor.name}"
          orientation="$laptop_orientation"
          total_count=''${#laptop_wallpapers[@]}
          current_num=$((laptop_index + 1))
      else
          ${pkgs.dunst}/bin/dunstify -u critical "Background Error" "Could not determine active monitor"
          exit 1
      fi

      # Save state
      echo "external_index=$external_index" > "$state_file"
      echo "laptop_index=$laptop_index" >> "$state_file"

      # Preload and set wallpaper using hyprctl
      ${pkgs.hyprland}/bin/hyprctl hyprpaper preload "$next_wallpaper"
      ${pkgs.hyprland}/bin/hyprctl hyprpaper wallpaper "$monitor_name,$next_wallpaper"

      # Unload old wallpapers to free memory (get list of currently loaded, unload all except new one)
      loaded_wallpapers=$(${pkgs.hyprland}/bin/hyprctl hyprpaper listloaded | ${pkgs.gnugrep}/bin/grep -v "no wallpapers loaded" || true)
      if [[ -n "$loaded_wallpapers" ]]; then
          while IFS= read -r loaded; do
              if [[ "$loaded" != "$next_wallpaper" && -n "$loaded" ]]; then
                  ${pkgs.hyprland}/bin/hyprctl hyprpaper unload "$loaded" 2>/dev/null || true
              fi
          done <<< "$loaded_wallpapers"
      fi

      # Extract filename for display
      wallpaper_name=$(${pkgs.coreutils}/bin/basename "$next_wallpaper" | ${pkgs.gnused}/bin/sed 's/\.[^.]*$//')

      # Send notification
      ${pkgs.dunst}/bin/dunstify -t 3000 -i "$next_wallpaper" "Wallpaper Changed" "$wallpaper_name\n$current_num/$total_count • $(echo $monitor_name | ${pkgs.coreutils}/bin/cut -d'-' -f1) ($orientation)"
    '')
  ];
}
