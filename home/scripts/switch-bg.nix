{
  config,
  pkgs,
  ...
}: let
  themeName = config.colorScheme.slug or "nord";
  inherit (config.vars.paths) wallpapers;
in {
  home.packages = [
    (pkgs.writeShellScriptBin "switch-bg" ''
      set -euo pipefail

      THEME="${themeName}"
      WALLPAPERS_DIR="${wallpapers}/$THEME"
      STATE_FILE="$HOME/.cache/wallpaper-state"

      notify_error() {
        ${pkgs.dunst}/bin/dunstify -u critical "Background Error" "$1"
        exit 1
      }

      [[ -d "$WALLPAPERS_DIR" ]] \
        || notify_error "Directory '$WALLPAPERS_DIR' not found"

      # Focused monitor + its live transform. `|| true`: under `set -e`, read
      # returns nonzero on EOF (no focused monitor) and would abort before the
      # guard below; swallow it so the guard can emit the notification.
      read -r active_monitor active_transform < <(
        ${pkgs.hyprland}/bin/hyprctl monitors -j \
          | ${pkgs.jq}/bin/jq -r '.[] | select(.focused == true) | "\(.name) \(.transform)"'
      ) || true
      [[ -n "''${active_monitor:-}" ]] || notify_error "No focused monitor"

      orientation=horizontal
      [[ "$active_transform" == "1" || "$active_transform" == "3" ]] && orientation=vertical

      mapfile -t wallpapers < <(
        ${pkgs.findutils}/bin/find "$WALLPAPERS_DIR/$orientation" \
          -maxdepth 1 -type f \
          \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
          2>/dev/null \
          | ${pkgs.coreutils}/bin/sort -V
      )
      (( ''${#wallpapers[@]} > 0 )) \
        || notify_error "No wallpapers found in $WALLPAPERS_DIR/$orientation"

      declare -A indices
      ${pkgs.coreutils}/bin/mkdir -p "$(dirname "$STATE_FILE")"
      ${pkgs.coreutils}/bin/touch "$STATE_FILE"
      while IFS='=' read -r key value; do
        [[ -z "$key" ]] && continue
        indices[$key]="$value"
      done < "$STATE_FILE"

      if [[ -v indices[$active_monitor] ]]; then
        idx=$(( (indices[$active_monitor] + 1) % ''${#wallpapers[@]} ))
      else
        idx=0
      fi
      indices[$active_monitor]=$idx
      next_wallpaper="''${wallpapers[$idx]}"

      tmp_state=$(${pkgs.coreutils}/bin/mktemp "$STATE_FILE.XXXXXX")
      for m in "''${!indices[@]}"; do
        printf '%s=%s\n' "$m" "''${indices[$m]}" >> "$tmp_state"
      done
      ${pkgs.coreutils}/bin/mv "$tmp_state" "$STATE_FILE"

      ${pkgs.hyprland}/bin/hyprctl hyprpaper wallpaper "$active_monitor,$next_wallpaper"

      wallpaper_name=$(${pkgs.coreutils}/bin/basename "$next_wallpaper" \
        | ${pkgs.gnused}/bin/sed 's/\.[^.]*$//')
      monitor_label="''${active_monitor%%-*}"
      total=''${#wallpapers[@]}

      ${pkgs.dunst}/bin/dunstify -t 3000 -i "$next_wallpaper" \
        "Wallpaper Changed" \
        "$wallpaper_name\n$((idx + 1))/$total • $monitor_label ($orientation)"
    '')
  ];
}
