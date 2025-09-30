{ config, pkgs, ... }:
let
  # nix-colors exposes this when you configure it in home-manager
  themeName = config.colorScheme.slug or "default";
in {
  home.packages = [
    (pkgs.writeShellScriptBin "switch-bg" ''
      set -euo pipefail

      cur_theme_name="${themeName}"
      backgrounds_dir="$HOME/Pictures/backgrounds/$cur_theme_name"

      # Check if backgrounds directory exists
      if [[ ! -d "$backgrounds_dir" ]]; then
          dunstify -u critical "Background Error" "Directory '$backgrounds_dir' not found"
          exit 1
      fi

      # Get all image files in the theme directory, sorted naturally
      mapfile -t backgrounds < <(find "$backgrounds_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort -V)

      if [[ ''${#backgrounds[@]} -eq 0 ]]; then
          dunstify -u critical "Background Error" "No image files found in '$backgrounds_dir'"
          exit 1
      fi

      # Get current wallpaper from swww (handle case where swww isn't running or no wallpaper set)
      current_wallpaper=$(swww query 2>/dev/null | grep -oP '(?<=image: ).*' | head -n1 || echo "")
      
      # Find current background index
      current_index=-1
      if [[ -n "$current_wallpaper" ]]; then
          for i in "''${!backgrounds[@]}"; do
              if [[ "''${backgrounds[$i]}" == "$current_wallpaper" ]]; then
                  current_index=$i
                  break
              fi
          done
      fi

      # Calculate next background index (cycle through)
      if [[ $current_index -eq -1 ]]; then
          # No current wallpaper or not in our theme directory, start from beginning
          next_index=0
      else
          next_index=$(( (current_index + 1) % ''${#backgrounds[@]} ))
      fi

      next_background="''${backgrounds[$next_index]}"

      # Set the wallpaper with random transition
      swww img "$next_background" --transition-type random --transition-duration 0.5

      # Extract just the filename for display
      background_name=$(basename "$next_background" | sed 's/\.[^.]*$//')
      
      # Send notification about wallpaper change
      dunstify -t 3000 -i "$next_background" "Wallpaper Changed" "$background_name\n$(( next_index + 1 ))/''${#backgrounds[@]} • $cur_theme_name theme"
    '')
  ];
}
