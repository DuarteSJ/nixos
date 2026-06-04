# Runtime monitor reconciliation — now event-driven in Lua instead of a
# socat/jq/flock shell loop.  Hyprland handles per-monitor specs declaratively
# via the `monitor` array; this covers what the static config can't:
#
#   • Disables the laptop panel when externals are present (preferExternal)
#     and re-enables it when the last external is unplugged.
#   • Pins the configured workspaces to whichever monitor is primary
#     (first external if any, else laptop).
#   • Per-monitor gaps (#5): tighter gaps on the small laptop panel, the
#     configured gaps once an external is attached.
#   • Sets wallpapers for every active monitor, orientation from live transform.
#
# `setup` is a Lua snippet meant to run inside the `hyprland.start` handler.
# It defines `reconcile()` (idempotent) and subscribes it to monitor.added /
# monitor.removed via short oneshot timers (debounce, replacing `sleep 0.3`).
# `reconcile` re-queries live state every call, so it's robust to whatever
# the event callbacks are or aren't passed.
{
  pkgs,
  laptop,
  workspaces,
  preferExternal,
  themeName,
  wallpapersPath,
  gaps,
}: let
  # Lua expression that re-enables the laptop panel with its full spec.
  laptopEnable =
    ''hl.monitor({ output = LAPTOP, mode = "${laptop.mode}", position = "${laptop.position}", scale = "${laptop.scale}", disabled = false''
    + (
      if laptop.transform != 0
      then '', transform = ${toString laptop.transform}''
      else ""
    )
    + " })";

  # Small helper: pick newest wallpaper for <monitor> <orientation> and push it
  # to hyprpaper.  Filesystem globbing has no Lua-sandbox equivalent, so this
  # stays a tiny shell script invoked per-monitor via hl.exec_cmd.
  setWallpaper = pkgs.writeShellScript "set-wallpaper" ''
    set -euo pipefail
    monitor="$1"
    orientation="$2"
    dir="${wallpapersPath}/${themeName}/$orientation"
    wp=$(${pkgs.findutils}/bin/find "$dir" -maxdepth 1 -type f \
           \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null \
         | ${pkgs.coreutils}/bin/sort -V | ${pkgs.coreutils}/bin/head -n1)
    [ -n "$wp" ] || exit 0
    hyprctl hyprpaper wallpaper "$monitor,$wp" 2>/dev/null || true
  '';

  wsList = builtins.concatStringsSep ", " (map toString workspaces);
  preferExternalLua =
    if preferExternal
    then "true"
    else "false";
  gapsIn = gaps / 2;

  setup = ''
    -- ====================================================================
    -- Monitor reconciliation (event-driven; replaces the socat shell loop)
    -- ====================================================================
    local LAPTOP           = "${laptop.name}"
    local PREFER_EXTERNAL  = ${preferExternalLua}
    local WORKSPACES       = { ${wsList} }

    local function enableLaptop()
      ${laptopEnable}
    end

    local function reconcile()
      local mons = hl.get_monitors()

      -- Primary = first non-laptop monitor, else laptop.
      local externalPrimary = nil
      for _, m in ipairs(mons) do
        if m.name ~= LAPTOP then
          externalPrimary = externalPrimary or m.name
        end
      end
      local hasExt  = externalPrimary ~= nil
      local primary = externalPrimary or LAPTOP

      -- #5 Per-monitor conditional config: tighter gaps on the laptop-only
      -- layout, the configured gaps once an external is attached.
      hl.config({
        general = {
          gaps_out = hasExt and ${toString gaps} or 1,
          gaps_in  = hasExt and ${toString gapsIn} or 0,
        },
      })

      -- Pin configured workspaces to primary (rule for future, move existing).
      -- Done BEFORE toggling laptop visibility: moving workspaces triggers a
      -- monitor reconfiguration that re-asserts the laptop's static `monitor`
      -- rule (which has no `disabled`), so a disable issued earlier would be
      -- silently undone.  Move first, disable last.
      for _, ws in ipairs(WORKSPACES) do
        hl.workspace_rule({ workspace = ws, monitor = primary })
        local w = hl.get_workspace(ws)
        if w and w.monitor and w.monitor.name ~= primary then
          hl.dispatch(hl.dsp.workspace.move({ workspace = ws, monitor = primary }))
        end
      end

      -- Wallpaper per active monitor, orientation from live transform.
      for _, m in ipairs(hl.get_monitors()) do
        local orient = (m.transform == 1 or m.transform == 3) and "vertical" or "horizontal"
        hl.exec_cmd("${setWallpaper} " .. m.name .. " " .. orient)
      end

      -- Laptop panel visibility LAST, so nothing reconfigures monitors after
      -- and re-enables the panel.  Disabling eDP-1 here auto-relocates any
      -- workspace still on it to `primary`.
      if PREFER_EXTERNAL and hasExt then
        hl.monitor({ output = LAPTOP, disabled = true })
      else
        enableLaptop()
      end
    end

    -- Debounced reconcile: re-run a short moment after a topology change so
    -- Hyprland has settled (replaces the old `sleep 0.3`).
    local function scheduleReconcile()
      hl.timer(function() reconcile() end, { timeout = 300, type = "oneshot" })
    end

    hl.on("monitor.added",   scheduleReconcile)
    hl.on("monitor.removed", scheduleReconcile)

    -- First pass once hyprpaper has had a moment to come up.
    hl.timer(function() reconcile() end, { timeout = 500, type = "oneshot" })
  '';
in {
  inherit setup setWallpaper;
}
