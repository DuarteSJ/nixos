# Per-monitor wallpapers, via hyprpaper IPC.
#
# One script, `wallpaper`, owns everything: the per-theme image list, the
# orientation rule and the remembered choice.
#
#   wallpaper apply MON   set MON's remembered wallpaper (or the first one)
#   wallpaper next        advance the focused monitor (Super+Shift+N)
#
# `apply` runs for every live monitor on each config load (startup sequence
# in default.nix), and orientation comes from each monitor's live transform,
# so a display no profile has ever heard of still gets a correct wallpaper.
# `next` reads what is actually on screen from `hyprctl hyprpaper
# listactive` instead of trusting a stored index, and only records the new
# choice once hyprpaper has accepted it — so the remembered choice and the
# screen can't disagree, and a reload restores the choice instead of
# snapping back to the first image.
#
# Also imported by home/scripts/switch-bg.nix, which puts the same package
# on PATH.
{
  pkgs,
  hyprland,
  notifyPkg,
  themeName,
  wallpapersPath,
}: let
  inherit (pkgs) lib;

  package = pkgs.writeShellApplication {
    name = "wallpaper";
    runtimeInputs = [
      hyprland
      notifyPkg
      pkgs.jq
      pkgs.findutils
      pkgs.coreutils
    ];
    text = ''
      THEME_DIR=${lib.escapeShellArg "${wallpapersPath}/${themeName}"}
      # monitor:orientation=path, one per line.  A path, not an index: an
      # index silently points elsewhere once the directory changes.
      STATE_FILE="''${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-current"

      # Transforms 1/3 rotate landscape->portrait; 5/7 are their flipped
      # variants.  All four mean a portrait panel.
      orientation_of() {
        case "$1" in
          1 | 3 | 5 | 7) echo vertical ;;
          *) echo horizontal ;;
        esac
      }

      # Fills the `wallpapers` array, version-sorted (deterministic order
      # within the curated per-theme dir).
      list_wallpapers() {
        mapfile -t wallpapers < <(
          find "$THEME_DIR/$1" -maxdepth 1 -type f \
            \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
            2>/dev/null | sort -V
        )
      }

      state_get() {
        [[ -f "$STATE_FILE" ]] || return 0
        local key value
        while IFS='=' read -r key value; do
          if [[ "$key" == "$1" ]]; then
            printf '%s\n' "$value"
            return 0
          fi
        done < "$STATE_FILE"
      }

      state_set() {
        mkdir -p "$(dirname "$STATE_FILE")"
        local tmp key value
        tmp=$(mktemp "$STATE_FILE.XXXXXX")
        if [[ -f "$STATE_FILE" ]]; then
          while IFS='=' read -r key value; do
            if [[ -n "$key" && "$key" != "$1" ]]; then
              printf '%s=%s\n' "$key" "$value"
            fi
          done < "$STATE_FILE" > "$tmp"
        fi
        printf '%s=%s\n' "$1" "$2" >> "$tmp"
        mv "$tmp" "$STATE_FILE"
      }

      # What hyprpaper is showing on monitor $1, if anything.
      current_of() {
        local line
        while IFS= read -r line; do
          if [[ "$line" == "$1: "* ]]; then
            printf '%s\n' "''${line#"$1: "}"
            return 0
          fi
        done < <(hyprctl hyprpaper listactive 2>/dev/null)
      }

      index_of() {
        local i
        for i in "''${!wallpapers[@]}"; do
          if [[ "''${wallpapers[$i]}" == "$1" ]]; then
            echo "$i"
            return 0
          fi
        done
        echo -1
      }

      # Run from Hyprland for every monitor on each config load: stay quiet
      # and never fail loudly.
      cmd_apply() {
        local mon="$1" transform orient want wp
        transform=$(hyprctl monitors -j \
          | jq -r --arg m "$mon" '.[] | select(.name == $m) | .transform') || true
        [[ -n "$transform" ]] || exit 0
        orient=$(orientation_of "$transform")
        list_wallpapers "$orient"
        (( ''${#wallpapers[@]} > 0 )) || exit 0
        want=$(state_get "$mon:$orient")
        wp="''${wallpapers[0]}"
        if [[ -n "$want" ]] && (( $(index_of "$want") >= 0 )); then
          wp="$want"
        fi
        hyprctl hyprpaper wallpaper "$mon,$wp" >/dev/null 2>&1 || true
      }

      notify_error() {
        notify -u critical "Background Error" "$1"
        exit 1
      }

      cmd_next() {
        local mon transform orient cur idx wp name
        [[ -d "$THEME_DIR" ]] || notify_error "Directory '$THEME_DIR' not found"
        # `|| true`: under `set -e`, read returns nonzero on EOF (no focused
        # monitor) and would abort before the guard below can notify.
        read -r mon transform < <(
          hyprctl monitors -j \
            | jq -r '.[] | select(.focused == true) | "\(.name) \(.transform)"'
        ) || true
        [[ -n "''${mon:-}" ]] || notify_error "No focused monitor"
        orient=$(orientation_of "$transform")
        list_wallpapers "$orient"
        (( ''${#wallpapers[@]} > 0 )) \
          || notify_error "No wallpapers found in $THEME_DIR/$orient"

        cur=$(current_of "$mon")
        idx=$(index_of "$cur")
        idx=$(( (idx + 1) % ''${#wallpapers[@]} ))
        wp="''${wallpapers[$idx]}"

        hyprctl hyprpaper wallpaper "$mon,$wp" >/dev/null \
          || notify_error "hyprpaper rejected $wp"
        state_set "$mon:$orient" "$wp"

        name=$(basename "$wp")
        notify -r wallpaper -t 3000 -i "$wp" \
          "Wallpaper Changed" \
          "''${name%.*}\n$((idx + 1))/''${#wallpapers[@]} • ''${mon%%-*} ($orient)"
      }

      case "''${1:-}" in
        apply) [[ -n "''${2:-}" ]] || { echo "usage: wallpaper apply MONITOR" >&2; exit 2; }
               cmd_apply "$2" ;;
        next) cmd_next ;;
        *) echo "usage: wallpaper apply MONITOR | wallpaper next" >&2; exit 2 ;;
      esac
    '';
  };

  # Lua side: push the remembered wallpaper to every live monitor.  Run by
  # the deferred startup sequence in default.nix, after the monitor
  # manager's first pass.  No event subscriptions: every topology change
  # goes through a config reload, which re-runs that sequence.
  setup = ''
    -- ====================================================================
    -- Wallpapers
    -- ====================================================================
    function _G.hlWallpapers()
      for _, m in ipairs(hl.get_monitors()) do
        hl.exec_cmd("${lib.getExe package} apply " .. shq(m.name))
      end
    end
  '';
in {
  inherit package setup;
}
