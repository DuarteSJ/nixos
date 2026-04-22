{
  config,
  pkgs,
  ...
}: let
  themeName = config.colorScheme.slug or "nord";

  orientationOf = m:
    if m.transform == 1 || m.transform == 3
    then "vertical"
    else "horizontal";

  allMonitors = [config.monitors.laptop] ++ config.monitors.external;

  # "name|orientation" lines consumed by the bash script below.
  monitorsLines = builtins.concatStringsSep "\n" (map
    (m: "${m.name}|${orientationOf m}")
    allMonitors);
in {
  home.packages = [
    (pkgs.writeShellScriptBin "switch-bg" ''
      set -euo pipefail

      THEME="${themeName}"
      WALLPAPERS_DIR="$HOME/Pictures/wallpapers/$THEME"
      STATE_FILE="$HOME/.cache/wallpaper-state"

      # Injected from Nix: one "name|orientation" per line.
      MONITORS="${monitorsLines}"

      notify_error() {
        ${pkgs.dunst}/bin/dunstify -u critical "Background Error" "$1"
        exit 1
      }

      [[ -d "$WALLPAPERS_DIR" ]] \
        || notify_error "Directory '$WALLPAPERS_DIR' not found"

      declare -A orientation_of
      while IFS='|' read -r name orient; do
        [[ -z "$name" ]] && continue
        orientation_of[$name]="$orient"
      done <<< "$MONITORS"

      active_monitor=$(hyprctl monitors -j \
        | ${pkgs.jq}/bin/jq -r '.[] | select(.focused == true) | .name')

      [[ -v orientation_of[$active_monitor] ]] \
        || notify_error "Unrecognised active monitor: $active_monitor"

      # Load state, keeping only entries for known monitors so stale
      # keys from removed monitors drop on the next write.
      declare -A indices
      ${pkgs.coreutils}/bin/mkdir -p "$(dirname "$STATE_FILE")"
      ${pkgs.coreutils}/bin/touch "$STATE_FILE"
      while IFS='=' read -r key value; do
        [[ -z "$key" ]] && continue
        [[ -v orientation_of[$key] ]] || continue
        indices[$key]="$value"
      done < "$STATE_FILE"

      orientation="''${orientation_of[$active_monitor]}"
      mapfile -t wallpapers < <(
        ${pkgs.findutils}/bin/find "$WALLPAPERS_DIR/$orientation" \
          -maxdepth 1 -type f \
          \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
          2>/dev/null \
          | ${pkgs.coreutils}/bin/sort -V
      )
      (( ''${#wallpapers[@]} > 0 )) \
        || notify_error "No wallpapers found in $WALLPAPERS_DIR/$orientation"

      # First time we've seen this monitor → show index 0.
      if [[ -v indices[$active_monitor] ]]; then
        idx=$(( (indices[$active_monitor] + 1) % ''${#wallpapers[@]} ))
      else
        idx=0
      fi
      indices[$active_monitor]=$idx
      next_wallpaper="''${wallpapers[$idx]}"

      # Persist state atomically.
      tmp_state=$(${pkgs.coreutils}/bin/mktemp "$STATE_FILE.XXXXXX")
      for m in "''${!indices[@]}"; do
        printf '%s=%s\n' "$m" "''${indices[$m]}" >> "$tmp_state"
      done
      ${pkgs.coreutils}/bin/mv "$tmp_state" "$STATE_FILE"

      hyprctl hyprpaper preload "$next_wallpaper"
      hyprctl hyprpaper wallpaper "$active_monitor,$next_wallpaper"

      # Collect wallpapers currently displayed on any monitor so we
      # don't unload something still in use elsewhere.
      declare -A in_use
      in_use[$next_wallpaper]=1
      while IFS='=' read -r _ path; do
        path="''${path# }"
        [[ -n "$path" ]] && in_use[$path]=1
      done < <(hyprctl hyprpaper listactive 2>/dev/null || true)

      while IFS= read -r loaded; do
        [[ -z "$loaded" || "$loaded" == "no wallpapers loaded" ]] && continue
        [[ -v in_use[$loaded] ]] || hyprctl hyprpaper unload "$loaded" 2>/dev/null || true
      done < <(hyprctl hyprpaper listloaded)

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
