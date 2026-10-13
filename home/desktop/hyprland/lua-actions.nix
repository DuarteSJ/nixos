# Inline Lua bind actions + top-level program.
# Native hl.config / hl.get_config — no /tmp state, no hyprctl eval.
{
  inline,
  rounding,
  base02,
  windowBorderLua,
  gaps,
  monitorManager,
  wallpaper,
}: let
  # general.gaps_out comes back as CCssGapData (a {top,right,bottom,left}
  # table), not a number — pull a single edge before doing arithmetic.
  gapsOutNum = ''
    (function()
      local g = hl.get_config("general.gaps_out")
      if type(g) == "table" then return g.top or g.left or 0 end
      return g or 0
    end)()'';
in {
  # Productivity toggle: persistent state lives in the closure upvalue, config
  # applied natively via hl.config — no /tmp, no subprocess, no hyprctl eval.
  prodToggle = inline ''
    (function()
      local on = false
      return function()
        on = not on
        hl.config({
          animations = { enabled = not on },
          general    = {
            col = on
              and { active_border = "rgba(${base02}aa)", inactive_border = "rgba(${base02}aa)" }
              or  ${windowBorderLua},
          },
          decoration = {
            rounding     = on and 0 or ${toString rounding},
            dim_inactive = on,
            dim_strength = on and 0.15 or 0.0,
          },
        })
        -- #6 Gaps: flat 0 in focus mode; otherwise restore the configured
        -- baseline (shared nix source with the static config block).
        if on then
          hl.config({ general = { gaps_in = 0, gaps_out = 0 } })
        else
          ${gaps.baselineGapsLua}
        end
        -- focusOn/focusOff, not hide/reveal: focus mode hides the bar on top of
        -- Super+B rather than overwriting it.  A reload resets `on` to false
        -- and the config to baseline; `topLevel` sends `focusOff` to match.
        hl.exec_cmd("qs -c shell ipc call bar " .. (on and "focusOn" or "focusOff"))
      end
    end)()'';

  # Gap +/- : read live value, clamp, write back.
  incGaps = inline ''
    function()
      local out = ${gapsOutNum} + 2
      hl.config({
        general    = { gaps_out = out, gaps_in = math.floor(out / 2) },
        decoration = { rounding = ${toString rounding} },
      })
    end'';
  decGaps = inline ''
    function()
      local out = ${gapsOutNum} - 2
      if out < 0 then out = 0 end
      hl.config({
        general    = { gaps_out = out, gaps_in = math.floor(out / 2) },
        decoration = { rounding = out > 0 and ${toString rounding} or 0 },
      })
    end'';

  # Cursor magnifier (native cursor:zoom_factor): step by `offset`, clamp 1..3.
  cursorZoom = let
    minZoom = "1";
    maxZoom = "3";
    mk = offset:
      inline ''
        function()
          local current = (hl.get_config("cursor.zoom_factor") or ${minZoom}) + ${offset}
          current = math.max(${minZoom}, math.min(${maxZoom}, current))
          hl.config({ cursor = { zoom_factor = current } })
        end'';
  in {
    zoomIn = mk "0.5";
    zoomOut = mk "-0.5";
  };

  # Cycle the active workspace's tiled layout: scrolling -> dwindle -> master
  # -> monocle -> (wrap). Per-workspace via workspace_rule.
  cycleLayout = inline ''
    function()
      local layouts     = { "scrolling", "dwindle", "master", "monocle" }
      local workspace   = hl.get_active_workspace()
      local next_layout = "dwindle"
      if not workspace then
        return
      end
      for i = 1, #layouts do
        if layouts[i] == workspace.tiled_layout then
          local next_layout_idx = (i % #layouts) + 1
          next_layout = layouts[next_layout_idx]
          break
        end
      end
      hl.workspace_rule({ workspace = workspace.name, layout = next_layout })
      -- -r reuses one notification slot so rapid toggles update in place.
      hl.exec_cmd("notify -r 7777 -t 1500 'Layout' '" .. next_layout .. "'")
    end'';

  # Cycle the active window: tiled -> floating -> fullscreen -> tiled.
  # win.fullscreen is the internal eFullscreenMode bitmask (0 none,
  # 1 maximized, 2 fullscreen); unset must name the mode actually active or
  # it no-ops.  A fullscreened float stays floating underneath, so leaving
  # fullscreen also unfloats to land back on tiled.
  cycleWindowMode = inline ''
    function()
      local win = hl.get_active_window()
      if not win then
        return
      end
      if win.fullscreen ~= 0 then
        local mode = win.fullscreen == 1 and "maximized" or "fullscreen"
        hl.dispatch(hl.dsp.window.fullscreen({ mode = mode, action = "unset" }))
        if win.floating then
          hl.dispatch(hl.dsp.window.float({ action = "unset" }))
        end
      elseif win.floating then
        hl.dispatch(hl.dsp.window.fullscreen({ action = "set" }))
      else
        hl.dispatch(hl.dsp.window.float({ action = "set" }))
      end
    end'';

  # Monitor status: current profile + per-output workspace mapping.
  monitorStatus = inline monitorManager.statusAction;

  # Lid closed: lock, then suspend — unless another output is up (docked,
  # clamshell).  logind's lid handling is off (system/default.nix) so this is
  # the only suspend.  The sleep gives hyprlock time to cover the screen.
  lidClose = inline ''
    function()
      for _, m in ipairs(hl.get_monitors()) do
        if m.name ~= "${monitorManager.builtinName}" then return end
      end
      hl.exec_cmd("hyprlock & sleep 0.5; systemctl suspend")
    end'';

  # Top-level program, for `extraConfig`.  Runs on every config load, so it
  # comes back after the `hyprctl reload` that monitor hotplug and
  # nixos-rebuild switch perform (a hyprland.start handler would not).
  topLevel = ''
    -- hl.on / hl.timer return GC-managed handles: if the Lua handle is
    -- collected, Hyprland drops the subscription and the callback silently
    -- stops firing.  Anchor every long-lived handle in a global.
    _G.__hlHandles = _G.__hlHandles or {}
    local function keep(h) _G.__hlHandles[#_G.__hlHandles + 1] = h; return h end

    -- A load resets prodToggle to off and the config to baseline; bring the
    -- bar's focus-mode hide in line.  Deferred like the monitor manager's
    -- first pass; harmless before Quickshell is up (focus mode starts off).
    keep(hl.timer(function()
      hl.exec_cmd("qs -c shell ipc call bar focusOff")
    end, { timeout = 500, type = "oneshot" }))

    -- Event handler — notify when a window marks itself urgent.
    keep(hl.on("window.urgent", function(win)
      -- win.class is app-controlled and is interpolated into the single-quoted
      -- shell arg below; strip single quotes (the only char that can break out
      -- of the quotes) and backslashes so a crafted class can't inject shell.
      local who = (win and win.class) or "A window"
      who = who:gsub("'", ""):gsub("''\\''\\", "")
      hl.exec_cmd("notify -u low 'Attention' '" .. who .. " needs attention'")
    end))
  '';
}
