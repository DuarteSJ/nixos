# Long-running script (exec-once) that reconciles runtime monitor state.
# Hyprland handles per-monitor specs declaratively via the `monitor` array
# (including the desc:-rules for known externals and the catch-all for
# unknown displays); this script covers what Hyprland can't:
#
#   • Disables the laptop panel when externals are present (preferExternal)
#     and re-enables it when the last external is unplugged.
#   • Pins the configured workspaces to whichever monitor is primary
#     (first external if any, else laptop).
#
# Wallpapers are handled by the Noctalia shell, not here.
#
# apply_state is idempotent and drives every code path — startup, hotplug,
# unplug.
{
  pkgs,
  laptop,
  workspaces,
  preferExternal,
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
    set -euo pipefail
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
    }

    # Wait for Hyprland's event socket to be ready.
    until [[ -S "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" ]]; do
      sleep 0.2
    done

    apply_state

    # Reconcile on every topology change.
    ${pkgs.socat}/bin/socat - \
      "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" \
    | while IFS= read -r line; do
        event="${"$"}{line%%>>*}"
        case "$event" in
          monitoradded|monitorremoved)
            sleep 0.3
            apply_state
            ;;
        esac
      done
  ''
