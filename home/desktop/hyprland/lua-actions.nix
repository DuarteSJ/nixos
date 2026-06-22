# Inline Lua bind actions + startup handler body.
# Native hl.config / hl.get_config — no /tmp state, no hyprctl eval.
{
  inline,
  rounding,
  base02,
  windowBorderLua,
  monitorManager,
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
        -- #6 Gaps: flat 0 in focus mode; otherwise restore the topology-derived
        -- baseline via the same writer reconcile() uses, so the two can't drift.
        -- After a `hyprctl reload` the start handler (and _G.hlBaselineGaps) is
        -- gone until relogin, but this keybind closure survives — so without a
        -- fallback the restore branch silently no-ops and gaps stay pinned at 0.
        -- Recompute the same baseline inline (shared nix source) in that case.
        if on then
          hl.config({ general = { gaps_in = 0, gaps_out = 0 } })
        elseif _G.hlBaselineGaps then
          _G.hlBaselineGaps()
        else
          ${monitorManager.baselineGapsLua}
        end
        hl.exec_cmd(on and "pkill waybar" or "pgrep waybar >/dev/null || waybar")
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
      hl.exec_cmd("dunstify -r 7777 -t 1500 'Layout' '" .. next_layout .. "'")
    end'';

  # Startup handler body (#2 events + #5 reconcile + #6 night dim)
  startupLua = ''
    hl.exec_cmd("waybar")

    ${monitorManager.setup}

    -- #2 Event handler — notify when a window marks itself urgent.
    hlKeep(hl.on("window.urgent", function(win)
      -- win.class is app-controlled and is interpolated into the single-quoted
      -- shell arg below; strip single quotes (the only char that can break out
      -- of the quotes) and backslashes so a crafted class can't inject shell.
      local who = (win and win.class) or "A window"
      who = who:gsub("'", ""):gsub("''\\''\\", "")
      hl.exec_cmd("dunstify -u critical 'Attention' '" .. who .. " needs attention'")
    end))
  '';
}
