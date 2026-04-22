# Single long-running script (exec-once) that owns all runtime monitor logic:
#
#   • Applies the correct state at startup (handles "already plugged in when
#     Hyprland starts" and "laptop only" equally).
#   • Reacts to monitoradded / monitorremoved socket events.
#   • Optionally disables the laptop panel when externals are present
#     (controlled by monitors.disableLaptopWhenExternal).
#   • Sets wallpapers via hyprpaper IPC for every active monitor.
#
# Shell-level constants are injected from Nix so this script has no
# dependency on hyprctl for config lookups — it only uses hyprctl to
# issue commands.
{
  pkgs,
  laptop,
  externals,
  disableLaptopWhenExternal,
  themeName,
  monitorEnableCmd,
}: let
  # Build the wallpaper-setting fragment for one monitor.
  # Picks the first image found in ~/Pictures/wallpapers/<theme>/<orientation>/
  wallpaperBlock = m: let
    dir =
      if m.transform == 1 || m.transform == 3
      then "vertical"
      else "horizontal";
  in ''
    set_wallpaper "${m.name}" "${dir}"
  '';
in
  pkgs.writeShellScript "monitor-manager" ''
    exec 9>/tmp/monitor-manager.lock
    flock -n 9 || exit 0
    LAPTOP="${laptop.name}"
    LAPTOP_ENABLE="${monitorEnableCmd laptop}"
    LAPTOP_DISABLE="hyprctl keyword monitor ${laptop.name},disable"
    DISABLE_WHEN_EXTERNAL="${
      if disableLaptopWhenExternal
      then "1"
      else "0"
    }"

    # Known external monitors: "name|enable-cmd" pairs, newline-separated.
    EXTERNALS="${builtins.concatStringsSep "\n" (map (m: "${m.name}|${monitorEnableCmd m}") externals)}"

    THEME="${themeName}"
    WALLPAPER_BASE="$HOME/Pictures/wallpapers/$THEME"

    # ----------------------------------------------------------------
    # Wallpaper helper
    # ----------------------------------------------------------------
    set_wallpaper() {
      local monitor="$1" orientation="$2"
      local dir="$WALLPAPER_BASE/$orientation"
      local wp
      wp=$(${pkgs.findutils}/bin/find "$dir" -maxdepth 1 -type f \
             \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) \
           | ${pkgs.coreutils}/bin/sort -V | ${pkgs.coreutils}/bin/head -n1)
      if [[ -n "$wp" ]]; then
        hyprctl hyprpaper preload "$wp"   2>/dev/null
        hyprctl hyprpaper wallpaper "$monitor,$wp" 2>/dev/null
      fi
    }

    # ----------------------------------------------------------------
    # Query helpers
    # ----------------------------------------------------------------
    connected_monitors() {
      hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[].name'
    }

    has_external() {
      connected_monitors | grep -qvF "$LAPTOP"
    }

    # ----------------------------------------------------------------
    # Apply correct monitor state (idempotent, call any time)
    # ----------------------------------------------------------------
    apply_state() {
      local connected
      connected=$(connected_monitors)

      # Re-enable any known external that is connected but currently
      # not active (e.g. after a Hyprland restart with it plugged in).
      while IFS='|' read -r name cmd; do
        [[ -z "$name" ]] && continue
        if echo "$connected" | grep -qF "$name"; then
          eval "$cmd"
        fi
      done <<< "$EXTERNALS"

      # Laptop visibility
      if [[ "$DISABLE_WHEN_EXTERNAL" == "1" ]]; then
        if has_external; then
          eval "$LAPTOP_DISABLE"
        else
          eval "$LAPTOP_ENABLE"
        fi
      fi

      # Set wallpapers for every active monitor
      set_wallpaper "$LAPTOP" "horizontal"
      ${builtins.concatStringsSep "\n      " (map wallpaperBlock externals)}
    }

    # ----------------------------------------------------------------
    # Wait for Hyprland socket and hyprpaper to be ready
    # ----------------------------------------------------------------
    until [[ -S "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" ]]; do
      sleep 0.2
    done
    until hyprctl hyprpaper listloaded >/dev/null 2>&1; do
      sleep 0.2
    done

    apply_state

    # ----------------------------------------------------------------
    # Event loop
    # ----------------------------------------------------------------
    ${pkgs.socat}/bin/socat - \
      "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" \
    | while IFS= read -r line; do
        event="${"$"}{line%%>>*}"
        data="${"$"}{line##*>>}"
        case "$event" in
          monitoradded)
            # Find and apply the config for this specific monitor
            while IFS='|' read -r name cmd; do
              [[ "$name" == "$data" ]] && eval "$cmd" && break
            done <<< "$EXTERNALS"
            # Disable laptop if needed
            if [[ "$DISABLE_WHEN_EXTERNAL" == "1" ]] && [[ "$data" != "$LAPTOP" ]]; then
              eval "$LAPTOP_DISABLE"
            fi
            # Wallpaper for the new monitor
            ${builtins.concatStringsSep "\n            " (map (m: ''
        [[ "$data" == "${m.name}" ]] && set_wallpaper "${m.name}" "${
          if m.transform == 1 || m.transform == 3
          then "vertical"
          else "horizontal"
        }"
      '')
      externals)}
            ;;
          monitorremoved)
            if [[ "$data" != "$LAPTOP" ]] && [[ "$DISABLE_WHEN_EXTERNAL" == "1" ]]; then
              sleep 0.3   # let hyprctl monitors reflect the removal
              has_external || eval "$LAPTOP_ENABLE"
            fi
            ;;
        esac
      done
  ''
