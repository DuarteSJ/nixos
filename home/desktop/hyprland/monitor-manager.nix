# Profile-based monitor reconciliation.
#
# Data model (see home/desktop/monitors.nix): an ordered list of profiles;
# the first whose `requires` are all present wins.  Matching is
# non-exclusive, so an unknown display never unmatches a known profile, and
# profiles are partial, so an output no profile names is never touched — it
# keeps whatever Hyprland's static catch-all `monitor` rule gave it.
#
# Apply order inside a profile is fixed by construction: enable -> workspaces
# -> disable.  Disable must come last because moving a workspace triggers a
# monitor reconfiguration that re-asserts the static `monitor` rule (which
# carries no `disabled`), silently undoing a disable issued earlier.  This
# used to be a comment you had to remember; now it's the structure.
#
# Exports `setup` (definitions; needs the prelude's notify(), see
# default.nix) and `topLevel` (setup + settling window + event subscriptions,
# for `extraConfig`).  The first pass itself, `_G.hlMonitorFirstPass()`, is
# run by the deferred startup sequence in default.nix.  See the note on
# `topLevel` re: surviving `hyprctl reload`.
{
  lib,
  specOf,
  outputs,
  profiles,
  announceUnknown,
}: let
  toLua = lib.generators.toLua {multiline = false;};
  stripNull = lib.filterAttrs (_: v: v != null);

  builtinNick =
    lib.head (lib.attrNames (lib.filterAttrs (_: o: o.builtin) outputs));
  builtinName = outputs.${builtinNick}.name;

  # A selector's base geometry, where it is knowable at eval time.
  # "@primaryExternal" resolves to a display we may never have seen, so it
  # has no base — only whatever the profile states explicitly.
  baseSpecOf = sel:
    if sel == "@builtin"
    then specOf outputs.${builtinNick}
    else if outputs ? ${sel}
    then specOf outputs.${sel}
    else {};

  # attrsOf -> array sorted by name (mapAttrsToList walks keys in order), so
  # generated Lua is deterministic.
  sortedPairs = lib.mapAttrsToList (key: value: {inherit key value;});

  mkEnable = e: {
    sel = e.key;
    spec = baseSpecOf e.key // stripNull e.value;
  };

  mkProfile = p: {
    inherit (p) name requires disable;
    enable = map mkEnable (sortedPairs p.enable);
    workspaces = map (w: {
      sel = w.key;
      ws = w.value;
    }) (sortedPairs p.workspaces);
  };

  luaOutputs = lib.mapAttrs (_: o:
    stripNull {
      inherit (o) name description builtin;
    })
  outputs;

  setup = ''
    -- ====================================================================
    -- Monitor reconciliation (profile-based)
    -- ====================================================================
    local BUILTIN   = ${toLua builtinName}
    local OUTPUTS   = ${toLua luaOutputs}
    local PROFILES  = ${toLua (map mkProfile profiles)}
    local ANNOUNCE  = ${lib.boolToString announceUnknown}

    -- Which configured output is this live monitor?  Connector name wins
    -- over EDID description so a `name`-pinned output (the panel) can't be
    -- stolen by a description prefix that happens to also match.
    local function matchNick(m)
      for nick, o in pairs(OUTPUTS) do
        if o.name and o.name == m.name then return nick end
      end
      for nick, o in pairs(OUTPUTS) do
        local d = o.description
        if d and m.description and m.description:sub(1, #d) == d then
          return nick
        end
      end
      return nil
    end

    -- Live state, resolved once per reconcile.  Note get_monitors() lists
    -- only ENABLED monitors, so a panel we disabled is absent here — that's
    -- why the builtin is treated as unconditionally present below.
    local function snapshot()
      local snap = { byNick = {}, externals = {}, unknown = {} }
      for _, m in ipairs(hl.get_monitors()) do
        local nick = matchNick(m)
        if nick then snap.byNick[nick] = m end
        if m.name ~= BUILTIN then
          snap.externals[#snap.externals + 1] = m
          if not nick then snap.unknown[#snap.unknown + 1] = m end
        end
      end
      return snap
    end

    -- Presence test, for `requires`.
    local function present(snap, sel)
      if sel == "@builtin" then return true end            -- always physical
      if sel == "@anyExternal" or sel == "@primaryExternal" then
        return #snap.externals > 0
      end
      return snap.byNick[sel] ~= nil
    end

    -- Selector -> (output identifier usable in a rule, is-it-connected).
    -- A known-but-absent output resolves to its static identifier so rules
    -- can be staged ahead of it being plugged in.
    local function resolve(snap, sel)
      if sel == "@builtin" then
        return BUILTIN, snap.byNick[${toLua builtinNick}] ~= nil
      end
      if sel == "@primaryExternal" then
        local m = snap.externals[1]
        if not m then return nil, false end
        return m.name, true
      end
      local o = OUTPUTS[sel]
      if not o then return nil, false end
      local m = snap.byNick[sel]
      if m then return m.name, true end
      if o.name then return o.name, false end
      return "desc:" .. o.description, false
    end

    local function pick(snap)
      for _, p in ipairs(PROFILES) do
        local ok = true
        for _, req in ipairs(p.requires) do
          if not present(snap, req) then ok = false; break end
        end
        if ok then return p end
      end
      -- Unreachable: an eval-time assertion forces the last profile to have
      -- requires = {}.  Kept so a schema regression degrades to "do nothing"
      -- rather than "nil index".
      return nil
    end

    local function apply(snap, p)
      -- 1. Geometry.  Explicit enables only; anything unnamed keeps what
      --    Hyprland's catch-all rule gave it.
      for _, e in ipairs(p.enable) do
        local out = resolve(snap, e.sel)
        if out then
          local spec = { output = out, disabled = false }
          for k, v in pairs(e.spec) do spec[k] = v end
          hl.monitor(spec)
        end
      end

      -- 2. Workspace pinning.  The rule is set unconditionally (so it takes
      --    effect whenever the output appears); the move only runs when the
      --    target is actually connected.
      for _, w in ipairs(p.workspaces) do
        local out, connected = resolve(snap, w.sel)
        if out then
          for _, ws in ipairs(w.ws) do
            hl.workspace_rule({ workspace = ws, monitor = out })
            if connected then
              local live = hl.get_workspace(ws)
              if live and live.monitor and live.monitor.name ~= out then
                hl.dispatch(hl.dsp.workspace.move({ workspace = ws, monitor = out }))
              end
            end
          end
        end
      end

      -- 3. Disable LAST — see header.  Runs even for outputs that aren't in
      --    get_monitors() (a panel we already disabled), which is what keeps
      --    the disable sticky across repeated reconciles.
      for _, sel in ipairs(p.disable) do
        local out = resolve(snap, sel)
        if out then hl.monitor({ output = out, disabled = true }) end
      end
    end

    -- Tell me about displays I haven't configured, with the exact string to
    -- paste into monitors.outputs.<nick>.description.  Once per description
    -- per session.
    local seenUnknown = {}
    local function announce(snap)
      if not ANNOUNCE then return end
      for _, m in ipairs(snap.unknown) do
        local d = m.description or m.name
        if not seenUnknown[d] then
          seenUnknown[d] = true
          -- EDID strings are device-controlled; notify() shell-quotes them.
          notify({ u = "low", t = 8000 }, "New display", d)
        end
      end
    end

    -- Human-readable snapshot of what the manager decided and what the
    -- compositor is actually showing.  Read it from a keybind, or from a
    -- shell with:
    --   hyprctl dispatch '(function() _G.hlMonitorStatusNotify()
    --                      return hl.dsp.exec_cmd("true") end)()'
    -- (`hyprctl dispatch` evaluates its argument as Lua in the compositor,
    -- so _G is reachable; it must still resolve to a dispatcher.)
    function _G.hlMonitorStatus()
      local lines = { "profile: " .. (_G.hlMonitorProfile or "(none yet)") }
      local snap = snapshot()
      for _, m in ipairs(hl.get_monitors()) do
        local nick = matchNick(m)
        local aw   = m.active_workspace
        lines[#lines + 1] = string.format(
          "%s  [%s]  ws %s",
          m.name,
          nick or "unconfigured",
          aw and tostring(aw.id) or "-")
      end
      -- get_monitors() only lists ENABLED outputs, so a panel we blanked is
      -- invisible above.  Say so explicitly rather than leaving it off.
      if not snap.byNick[${toLua builtinNick}] then
        lines[#lines + 1] = BUILTIN .. "  [${builtinNick}]  disabled"
      end
      return table.concat(lines, "\n")
    end

    -- Bindable: show the status as a notification.  -r reuses one slot so
    -- repeated presses update in place instead of stacking.
    function _G.hlMonitorStatusNotify()
      notify({ r = "monitors", t = 6000 }, "Monitors", _G.hlMonitorStatus())
    end

    -- Topology fingerprint: the external outputs that are up, minus any the
    -- active profile disables itself, so our own disable never reads as a
    -- change.  The builtin is left out for the same reason.
    local reconciledSkip, reconciledSig = {}, nil
    local function topologySig(snap, skip)
      local names = {}
      for _, m in ipairs(snap.externals) do
        if not skip[m.name] then names[#names + 1] = m.name end
      end
      table.sort(names)
      return table.concat(names, ",")
    end

    function _G.hlMonitorReconcile()
      local snap = snapshot()
      local p = pick(snap)
      if not p then return end
      apply(snap, p)
      -- For the status keybind.  No change-detection toast: every topology
      -- change goes through a reload, which wipes _G, so there is never a
      -- previous value to compare against.
      _G.hlMonitorProfile = p.name
      announce(snap)
      reconciledSkip = {}
      for _, sel in ipairs(p.disable) do
        local out = resolve(snap, sel)
        if out then reconciledSkip[out] = true end
      end
      reconciledSig = topologySig(snap, reconciledSkip)
    end

    -- Has a real hotplug landed since the last reconcile?  Returns the live
    -- fingerprint when it differs from the reconciled one, else nil (also nil
    -- before the first reconcile).  Checked when the settling window closes,
    -- since events inside it are swallowed.
    function _G.hlMonitorTopologyDrift()
      if reconciledSig == nil then return nil end
      local sig = topologySig(snapshot(), reconciledSkip)
      if sig ~= reconciledSig then return sig end
      return nil
    end
  '';

  # Top-level program.  Goes in `extraConfig`, which Home Manager appends to
  # the END of hyprland.lua — so it runs on every config load, including the
  # reload that `hyprctl reload` (and every nixos-rebuild switch) performs.
  #
  # Why profile matching lives at config-load time rather than in an event
  # handler: the static `monitor` rules rendered earlier in this same file are
  # the BASELINE — every configured output enabled with its geometry.  A
  # profile only ever subtracts from that baseline (disable) or overrides
  # geometry.  Since every load re-establishes the baseline before we run,
  # there is never anything to un-disable.
  #
  # That matters because Hyprland 0.55.4 cannot un-disable an output at all:
  # once hl.monitor{disabled=true} has been applied, hl.monitor{disabled=false}
  # is silently ignored — by connector name or `desc:`, with or without
  # force_renderer_reload.  A config reload is the only thing that clears it.
  # So a reload is exactly the primitive this design is built on, rather than
  # the failure mode it used to be.
  topLevel = ''
    ${setup}

    -- Settling window: our own disable makes Hyprland emit monitor.removed,
    -- which would otherwise trigger a reload, which would disable again...
    -- Swallow topology events from load until the window closes, a while
    -- after the first match (see hlMonitorFirstPass).  A real hotplug inside
    -- the window is swallowed too, so the close compares against what was
    -- reconciled and reloads if the outputs moved meanwhile.
    _G.__hlSettling = true

    -- Re-match from the baseline.  A successful reload wipes this VM, timers
    -- included, so the failsafe only fires if the reload did NOT happen
    -- (hyprctl failed, ...).  Without it __hlSettling would stay true and
    -- every later hotplug would be dropped for the rest of the session.  It
    -- reconciles in place (best effort: it cannot un-disable an output) and
    -- reopens the settling window, rather than retrying the reload blindly.
    local closeSettling
    local function reloadFromBaseline()
      _G.__hlSettling = true
      hl.exec_cmd("hyprctl reload")
      keep(hl.timer(function()
        _G.hlMonitorReconcile()
        keep(hl.timer(closeSettling, { timeout = 1000, type = "oneshot" }))
      end, { timeout = 5000, type = "oneshot" }))
    end

    -- Close the window, conservatively.  An output relinking after apply()
    -- set its mode can be absent for a moment, and a single sample would
    -- read that as a hotplug and reload -- which applies the mode again, and
    -- so on forever.  So a drift only counts if the SAME changed fingerprint
    -- is still there on a second sample 500 ms later; one that vanished was
    -- a blip, one that changed again is still moving and gets re-sampled.
    function closeSettling()
      local drift = _G.hlMonitorTopologyDrift()
      if not drift then _G.__hlSettling = false; return end
      keep(hl.timer(function()
        local again = _G.hlMonitorTopologyDrift()
        if not again then
          _G.__hlSettling = false
        elseif again == drift then
          reloadFromBaseline()
        else
          closeSettling()
        end
      end, { timeout = 500, type = "oneshot" }))
    end

    -- First match + arm the window close.  Called from the deferred startup
    -- sequence in default.nix (monitors are not up yet while the config is
    -- first parsed), so the window is timed from the match itself rather
    -- than from a second timer racing it.
    function _G.hlMonitorFirstPass()
      _G.hlMonitorReconcile()
      keep(hl.timer(closeSettling, { timeout = 1000, type = "oneshot" }))
    end

    -- A real topology change just reloads.  The reload re-runs this file from
    -- the baseline and re-matches — that IS the reconcile.  Nothing to
    -- re-derive at runtime, nothing to undo.
    local function onTopologyChange()
      if _G.__hlSettling then return end
      reloadFromBaseline()
    end

    keep(hl.on("monitor.added",   onTopologyChange))
    keep(hl.on("monitor.removed", onTopologyChange))
  '';

  # Bindable action: notify with the current profile + live monitor mapping.
  statusAction = "function() _G.hlMonitorStatusNotify() end";
in {
  inherit setup topLevel statusAction;
}
