# Long-running script (exec-once) that reconciles runtime monitor state.
# Hyprland handles per-monitor specs declaratively via the `monitor` array
# (including the desc:-rules for known externals and the catch-all for
# unknown displays); this script covers what Hyprland can't:
#
#   • Disables the laptop panel when externals are present (preferExternal)
#     and re-enables it when the last external is unplugged.
#   • Pins the configured workspaces to whichever monitor is primary
#     (first external if any, else laptop).
#   • Sets wallpapers for every active monitor, using the monitor's
#     live `transform` to pick horizontal/vertical.
#
# apply_state is idempotent and drives every code path — startup, hotplug,
# unplug.
{
  pkgs,
  laptop,
  workspaces,
  preferExternal,
  themeName,
}: let
  laptopSpec =
    "${laptop.name},${laptop.mode},${laptop.position},${laptop.scale}"
    + (
      if laptop.transform != 0
      then ",transform,${toString laptop.transform}"
      else ""
    );
in
  pkgs.writeShellScript "monitor-manager" ''
    exec 9>/tmp/monitor-manager.lock
    flock -n 9 || exit 0

    LAPTOP="${laptop.name}"
    LAPTOP_SPEC="${laptopSpec}"
    PREFER_EXTERNAL=${
      if preferExternal
      then "1"
      else "0"
    }
    WORKSPACES="${builtins.concatStringsSep " " (map toString workspaces)}"
    THEME="${themeName}"
    WALLPAPER_BASE="$HOME/Pictures/wallpapers/$THEME"

    set_wallpaper() {
      local monitor="$1" orientation="$2"
      local dir="$WALLPAPER_BASE/$orientation"
      local wp
      wp=$(${pkgs.findutils}/bin/find "$dir" -maxdepth 1 -type f \
             \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) \
             2>/dev/null \
           | ${pkgs.coreutils}/bin/sort -V | ${pkgs.coreutils}/bin/head -n1)
      [[ -n "$wp" ]] || return 0
      hyprctl hyprpaper preload "$wp"           2>/dev/null
      hyprctl hyprpaper wallpaper "$monitor,$wp" 2>/dev/null
    }

    apply_state() {
      local monitors_json has_external laptop_enabled primary
      monitors_json=$(hyprctl monitors -j)

      has_external=$(echo "$monitors_json" \
        | ${pkgs.jq}/bin/jq -r --arg l "$LAPTOP" 'any(.[]; .name != $l)')

      # Laptop visibility — only send the command when state needs to change.
      laptop_enabled=$(echo "$monitors_json" \
        | ${pkgs.jq}/bin/jq -r --arg l "$LAPTOP" 'any(.[]; .name == $l)')
      if [[ "$PREFER_EXTERNAL" == "1" && "$has_external" == "true" ]]; then
        if [[ "$laptop_enabled" == "true" ]]; then
          hyprctl keyword monitor "$LAPTOP,disable" >/dev/null
          sleep 0.2
          monitors_json=$(hyprctl monitors -j)
        fi
      else
        if [[ "$laptop_enabled" != "true" ]]; then
          hyprctl keyword monitor "$LAPTOP_SPEC" >/dev/null
          sleep 0.2
          monitors_json=$(hyprctl monitors -j)
        fi
      fi

      # Primary = first non-laptop monitor, else laptop.
      primary=$(echo "$monitors_json" | ${pkgs.jq}/bin/jq -r --arg l "$LAPTOP" \
        'map(select(.name != $l)) | if length > 0 then .[0].name else $l end')

      # Pin configured workspaces to primary.  Sets the rule (newly-created
      # workspaces land on primary) and moves any that currently exist
      # elsewhere.
      local workspaces_json
      workspaces_json=$(hyprctl workspaces -j)
      for ws in $WORKSPACES; do
        hyprctl keyword workspace "$ws, monitor:$primary" >/dev/null || true
        local ws_monitor
        ws_monitor=$(echo "$workspaces_json" \
          | ${pkgs.jq}/bin/jq -r --argjson ws "$ws" '.[] | select(.id == $ws) | .monitor')
        if [[ -n "$ws_monitor" && "$ws_monitor" != "$primary" ]]; then
          hyprctl dispatch moveworkspacetomonitor "$ws $primary" >/dev/null
        fi
      done

      # Wallpapers for every enabled monitor, orientation from live transform.
      while IFS=$'\t' read -r name transform; do
        [[ -z "$name" ]] && continue
        local orientation=horizontal
        [[ "$transform" == "1" || "$transform" == "3" ]] && orientation=vertical
        set_wallpaper "$name" "$orientation"
      done < <(echo "$monitors_json" \
        | ${pkgs.jq}/bin/jq -r '.[] | "\(.name)\t\(.transform)"')
    }

    # Wait for Hyprland and hyprpaper to be ready.
    until [[ -S "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" ]]; do
      sleep 0.2
    done
    until hyprctl hyprpaper listloaded >/dev/null 2>&1; do
      sleep 0.2
    done

    apply_state

    # Reconcile on every topology change.
    ${pkgs.socat}/bin/socat - \
      "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" \
    | while IFS= read -r line; do
        event="${"$"}{line%%>>*}"
        case "$event" in
          monitoradded|monitorremoved|monitorlayoutchanged)
            # monitorlayoutchanged (if Hyprland emits it on transform /
            # mode / position changes) lets rotation and similar updates
            # reach apply_state without a dedicated wrapper command.
            sleep 0.3
            apply_state
            ;;
        esac
      done
  ''
