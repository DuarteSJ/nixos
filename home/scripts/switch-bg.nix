{
  config,
  pkgs,
  ...
}: let
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
      # Get all image files in the theme directory, sorted naturally
      mapfile -t wallpapers < <(${pkgs.findutils}/bin/find "$wallpapers_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | ${pkgs.coreutils}/bin/sort -V)
      if [[ ''${#wallpapers[@]} -eq 0 ]]; then
          ${pkgs.dunst}/bin/dunstify -u critical "Background Error" "No image files found in '$wallpapers_dir'"
          exit 1
      fi
      # Get current wallpaper from swww (handle case where swww isn't running or no wallpaper set)
      current_wallpaper=$(${pkgs.swww}/bin/swww query 2>/dev/null | ${pkgs.gnugrep}/bin/grep -oP '(?<=image: ).*' | ${pkgs.coreutils}/bin/head -n1 || echo "")

      # Find current background index
      current_index=-1
      if [[ -n "$current_wallpaper" ]]; then
          for i in "''${!wallpapers[@]}"; do
              if [[ "''${wallpapers[$i]}" == "$current_wallpaper" ]]; then
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
          next_index=$(( (current_index + 1) % ''${#wallpapers[@]} ))
      fi
      next_background="''${wallpapers[$next_index]}"
      # Set the wallpaper with random transition
      ${pkgs.swww}/bin/swww img "$next_background" --transition-type random --transition-duration 0.5
      # Extract just the filename for display
      background_name=$(${pkgs.coreutils}/bin/basename "$next_background" | ${pkgs.gnused}/bin/sed 's/\.[^.]*$//')

      # Send notification about wallpaper change
      ${pkgs.dunst}/bin/dunstify -t 3000 -i "$next_background" "Wallpaper Changed" "$background_name\n$(( next_index + 1 ))/''${#wallpapers[@]} • $cur_theme_name theme"
    '')
  ];
}
