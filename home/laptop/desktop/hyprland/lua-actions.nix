# Inline Lua bind actions + top-level program.
# Native hl.config / hl.get_config — no /tmp state, no hyprctl eval.
#
# Bind actions are rendered into `settings`, i.e. BEFORE the extraConfig
# prelude in default.nix, so they reach its helpers (notify, shq) as globals
# at call time, not as upvalues.
{
  lib,
  inline,
  baseline,
  base02,
  monitorManager,
  qsIpc,
}: let
  toLua = lib.generators.toLua {multiline = false;};

  # general.gaps_out comes back as CCssGapData (a {top,right,bottom,left}
  # table), not a number — pull a single edge before doing arithmetic.
  gapsOutNum = ''
    (function()
      local g = hl.get_config("general.gaps_out")
      if type(g) == "table" then return g.top or g.left or 0 end
      return g or 0
    end)()'';

  # Inner gap as a fraction of the outer one, from the configured pair, so
  # stepping the gaps keeps a custom vars.gapsInner in proportion (and lands
  # exactly on it again at the configured outer gap).  Half when the outer
  # gap is 0 and there is no ratio to keep.
  innerRatio = let
    inherit (baseline.general) gaps_in gaps_out;
  in
    if gaps_out == 0
    then 0.5
    else gaps_in / (gaps_out * 1.0);

  # Focus mode: everything the baseline sets, flattened.  Same keys as the
  # baseline (plus dim_strength, inert once dim_inactive is off again), so
  # hl.config(BASELINE) undoes it completely.
  focus = {
    animations.enabled = false;
    general = {
      gaps_in = 0;
      gaps_out = 0;
      col = {
        active_border = "rgba(${base02}aa)";
        inactive_border = "rgba(${base02}aa)";
      };
    };
    decoration = {
      rounding = 0;
      dim_inactive = true;
      dim_strength = 0.15;
    };
  };
in {
  # Productivity toggle: persistent state lives in the closure upvalue, config
  # applied natively via hl.config — no /tmp, no subprocess, no hyprctl eval.
  # Off re-applies BASELINE, the same table the static config block in
  # default.nix is built from.
  prodToggle = inline ''
    (function()
      local BASELINE = ${toLua baseline}
      local FOCUS    = ${toLua focus}
      local on = false
      return function()
        on = not on
        hl.config(on and FOCUS or BASELINE)
        -- focusOn/focusOff, not hide/reveal: focus mode hides the bar on top of
        -- Super+B rather than overwriting it.  A reload resets `on` to false
        -- and the config to baseline; the startup sequence in default.nix
        -- sends `focusOff` to match.
        hl.exec_cmd("${qsIpc} bar " .. (on and "focusOn" or "focusOff"))
      end
    end)()'';

  # Gap +/- : read live value, step, clamp at 0, write back.  The inner gap
  # follows at the configured inner:outer ratio; rounding drops to 0 with the
  # gaps, so flush windows get square corners.
  inherit
    (let
      mk = delta:
        inline ''
          function()
            local out = math.max(0, ${gapsOutNum} + ${toString delta})
            hl.config({
              general    = { gaps_out = out, gaps_in = math.floor(out * ${toLua innerRatio} + 0.5) },
              decoration = { rounding = out > 0 and ${toString baseline.decoration.rounding} or 0 },
            })
          end'';
    in {
      incGaps = mk 2;
      decGaps = mk (-2);
    })
    incGaps
    decGaps
    ;

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
      notify({ r = "layout", t = 1500 }, "Layout", next_layout)
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

  # Top-level program, for `extraConfig` (after the shared prelude in
  # default.nix, which defines keep() and notify()).  Runs on every config
  # load, so it comes back after the `hyprctl reload` that monitor hotplug
  # and nixos-rebuild switch perform (a hyprland.start handler would not).
  topLevel = ''
    -- Event handler — notify when a window marks itself urgent.
    keep(hl.on("window.urgent", function(win)
      -- win.class is app-controlled; notify() shell-quotes it, so it is shown
      -- verbatim and cannot inject shell.
      local who = (win and win.class) or "A window"
      notify({ u = "low" }, "Attention", who .. " needs attention")
    end))
  '';
}
