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
  gapsOuter,
  gapsInner,
}: let
  # Lua expression that re-enables the laptop panel with its full spec.
  laptopEnable =
    ''hl.monitor({ output = LAPTOP, mode = "${laptop.mode}", position = "${laptop.position}", scale = ${toString laptop.scale}, disabled = false''
    + (
      if laptop.transform != 0
      then '', transform = ${toString laptop.transform}''
      else ""
    )
    + " })";

  # Small helper: pick a wallpaper for <monitor> <orientation> and push it to
  # hyprpaper.  `sort -V | head -n1` picks the first by version-sorted filename
  # (a deterministic choice within the curated per-theme dir), NOT the newest by
  # mtime.  Filesystem globbing has no Lua-sandbox equivalent, so this stays a
  # tiny shell script invoked per-monitor via hl.exec_cmd.
  setWallpaper = pkgs.writeShellApplication {
    name = "set-wallpaper";
    runtimeInputs = [pkgs.findutils pkgs.coreutils pkgs.hyprland];
    text = ''
      monitor="$1"
      orientation="$2"
      dir="${wallpapersPath}/${themeName}/$orientation"
      # `|| true`: head closes the pipe early, so sort takes SIGPIPE and the
      # pipeline returns non-zero — which would abort under set -o pipefail.
      wp=$(find "$dir" -maxdepth 1 -type f \
             \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null \
           | sort -V | head -n1) || true
      [ -n "$wp" ] || exit 0
      hyprctl hyprpaper wallpaper "$monitor,$wp" 2>/dev/null || true
    '';
  };

  wsList = builtins.concatStringsSep ", " (map toString workspaces);
  preferExternalLua = pkgs.lib.boolToString preferExternal;

  # #6 Topology-derived gap baseline as self-contained statements (laptop name
  # literal, no LAPTOP upvalue) so the same source can both define
  # _G.hlBaselineGaps inside the start handler AND be inlined from prodToggle's
  # restore path after a `hyprctl reload` has wiped that global.  One nix string
  # => the two callers can't drift.
  baselineGapsLua = ''
    local hasExt = false
    for _, m in ipairs(hl.get_monitors()) do
      if m.name ~= "${laptop.name}" then hasExt = true; break end
    end
    hl.config({
      general = {
        gaps_out = hasExt and ${toString gapsOuter} or 1,
        gaps_in  = hasExt and ${toString gapsInner} or 0,
      },
    })'';

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

    -- #6 Single source of truth for the topology-derived gap baseline: tight
    -- gaps on the laptop-only layout, the configured gaps once an external is
    -- attached.  Global so the productivity toggle (lua-actions) restores this
    -- exact baseline instead of hardcoding values that drift away from here.
    function _G.hlBaselineGaps()
      ${baselineGapsLua}
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

      -- #5/#6 Per-monitor conditional gaps via the shared baseline writer
      -- (also used by prodToggle's restore branch).
      _G.hlBaselineGaps()

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
        hl.exec_cmd("${pkgs.lib.getExe setWallpaper} " .. m.name .. " " .. orient)
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
    -- Hyprland has settled (replaces the old `sleep 0.3`).  Each call anchors a
    -- fresh oneshot timer in __hlHandles that's never pruned, but growth is
    -- bounded by the hotplug count for the session (the VM — and the table —
    -- reset on relogin), so the leak is negligible and not worth the GC risk of
    -- self-pruning a handle the callback still needs while it runs.
    local function scheduleReconcile()
      hlKeep(hl.timer(function() reconcile() end, { timeout = 300, type = "oneshot" }))
    end

    -- hl.on / hl.timer return GC-managed handles: if the Lua handle is
    -- collected, Hyprland drops the subscription from m_activeHandles and the
    -- callback silently stops firing.  Everything here runs inside the
    -- hyprland.start callback, so an unreferenced handle becomes unreachable the
    -- moment that callback returns and dies at the next GC.  That is why the
    -- 500ms first pass (fires before GC runs) works at login while the
    -- monitor.added / monitor.removed subscriptions go dead before any hotplug.
    -- Anchor every long-lived handle in a global so it lives for the session.
    -- hlKeep is also used by the rest of the start handler (default.nix).
    _G.__hlHandles = _G.__hlHandles or {}
    function hlKeep(h) _G.__hlHandles[#_G.__hlHandles + 1] = h; return h end

    hlKeep(hl.on("monitor.added",   scheduleReconcile))
    hlKeep(hl.on("monitor.removed", scheduleReconcile))

    -- First pass once hyprpaper has had a moment to come up.
    hlKeep(hl.timer(function() reconcile() end, { timeout = 500, type = "oneshot" }))
  '';
in {
  inherit setup setWallpaper baselineGapsLua;
}
