{
  config,
  pkgs,
  ...
}: let
  themeName = config.colorScheme.slug or "nord";
  inherit (config.vars.paths) wallpapers;
in {
  home.packages = [
    (pkgs.writeShellApplication {
      name = "switch-bg";
      runtimeInputs = [
        pkgs.dunst
        pkgs.hyprland
        pkgs.jq
        pkgs.findutils
        pkgs.coreutils
        pkgs.gnused
      ];
      text = ''
        shopt -s extglob

        THEME="${themeName}"
        WALLPAPERS_DIR="${wallpapers}/$THEME"
        STATE_FILE="$HOME/.cache/wallpaper-state"

        notify_error() {
          dunstify -u critical "Background Error" "$1"
          exit 1
        }

        [[ -d "$WALLPAPERS_DIR" ]] \
          || notify_error "Directory '$WALLPAPERS_DIR' not found"

        # Focused monitor + its live transform. `|| true`: under `set -e`, read
        # returns nonzero on EOF (no focused monitor) and would abort before the
        # guard below; swallow it so the guard can emit the notification.
        read -r active_monitor active_transform < <(
          hyprctl monitors -j \
            | jq -r '.[] | select(.focused == true) | "\(.name) \(.transform)"'
        ) || true
        [[ -n "''${active_monitor:-}" ]] || notify_error "No focused monitor"

        # Transforms 1/3 are rotated landscape->portrait; 5/7 are the flipped
        # variants. All four mean a portrait-oriented panel.
        orientation=horizontal
        [[ "$active_transform" == @(1|3|5|7) ]] && orientation=vertical

        # Each (monitor, orientation) pair keeps its own cycle position so
        # rotating a display doesn't scramble the other orientation's sequence.
        state_key="$active_monitor:$orientation"

        mapfile -t wallpapers < <(
          find "$WALLPAPERS_DIR/$orientation" \
            -maxdepth 1 -type f \
            \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
            2>/dev/null \
            | sort -V
        )
        (( ''${#wallpapers[@]} > 0 )) \
          || notify_error "No wallpapers found in $WALLPAPERS_DIR/$orientation"

        declare -A indices
        mkdir -p "$(dirname "$STATE_FILE")"
        touch "$STATE_FILE"
        while IFS='=' read -r key value; do
          [[ -z "$key" ]] && continue
          indices[$key]="$value"
        done < "$STATE_FILE"

        if [[ -v indices[$state_key] ]]; then
          idx=$(( (indices[$state_key] + 1) % ''${#wallpapers[@]} ))
        else
          idx=0
        fi
        indices[$state_key]=$idx
        next_wallpaper="''${wallpapers[$idx]}"

        tmp_state=$(mktemp "$STATE_FILE.XXXXXX")
        for m in "''${!indices[@]}"; do
          printf '%s=%s\n' "$m" "''${indices[$m]}" >> "$tmp_state"
        done
        mv "$tmp_state" "$STATE_FILE"

        hyprctl hyprpaper wallpaper "$active_monitor,$next_wallpaper"

        wallpaper_name=$(basename "$next_wallpaper" \
          | sed 's/\.[^.]*$//')
        monitor_label="''${active_monitor%%-*}"
        total=''${#wallpapers[@]}

        dunstify -t 3000 -i "$next_wallpaper" \
          "Wallpaper Changed" \
          "$wallpaper_name\n$((idx + 1))/$total • $monitor_label ($orientation)"
      '';
    })
  ];
}
