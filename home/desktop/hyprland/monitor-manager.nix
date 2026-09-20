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
# Exports `setup` (definitions; safe to evaluate anywhere) and `init` (event
# subscriptions + first pass), so the caller decides when subscriptions are
# established.  See the note on `init` re: surviving `hyprctl reload`.
{
  lib,
  outputs,
  profiles,
  announceUnknown,
}: let
  toLua = lib.generators.toLua {multiline = false;};
  stripNull = lib.filterAttrs (_: v: v != null);

  builtinNick =
    lib.head (lib.attrNames (lib.filterAttrs (_: o: o.builtin) outputs));
  builtinName = outputs.${builtinNick}.name;

  # Static geometry for an output, as an HL.MonitorSpec fragment.
  specOf = o:
    stripNull {
      inherit (o) mode position scale;
      transform =
        if o.transform != 0
        then o.transform
        else null;
    };

  # A selector's base geometry, where it is knowable at eval time.
  # "@primaryExternal" resolves to a display we may never have seen, so it
  # has no base — only whatever the profile states explicitly.
  baseSpecOf = sel:
    if sel == "@builtin"
    then specOf outputs.${builtinNick}
    else if outputs ? ${sel}
    then specOf outputs.${sel}
    else {};

  # attrsOf -> sorted array, so generated Lua is deterministic.
  sortedPairs = attrs:
    map (k: {
      key = k;
      value = attrs.${k};
    }) (lib.sort (a: b: a < b) (lib.attrNames attrs));

  mkEnable = e: let
    ov = stripNull (builtins.removeAttrs e.value ["mirror"]);
  in
    {
      sel = e.key;
      spec = baseSpecOf e.key // ov;
    }
    // lib.optionalAttrs (e.value.mirror != null) {mirror_sel = e.value.mirror;};

  mkProfile = p: {
    inherit (p) name requires disable overflow;
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
          if e.mirror_sel then
            local target = resolve(snap, e.mirror_sel)
            if target then spec.mirror = target end
          end
          hl.monitor(spec)
        end
      end

      -- 2. Workspace pinning.  The rule is set unconditionally (so it takes
      --    effect whenever the output appears); the move only runs when the
      --    target is actually connected.
      local claimed = {}
      for _, w in ipairs(p.workspaces) do
        local out, connected = resolve(snap, w.sel)
        if out then
          for _, ws in ipairs(w.ws) do
            claimed[ws] = true
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

      -- 3. Overflow: give unrecognised active displays something to hold, so
      --    a monitor you've never configured comes up usable rather than lit
      --    and empty.  Round-robin over however many there are.
      if #p.overflow > 0 and #snap.unknown > 0 then
        for i, ws in ipairs(p.overflow) do
          if not claimed[ws] then
            local m = snap.unknown[((i - 1) % #snap.unknown) + 1]
            hl.workspace_rule({ workspace = ws, monitor = m.name })
          end
        end
      end

      -- 4. Disable LAST — see header.  Runs even for outputs that aren't in
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
          -- EDID strings are device-controlled and land in a single-quoted
          -- shell arg; strip the only char that can break out.
          local safe = d:gsub("'", "")
          hl.exec_cmd(
            "dunstify -u low -t 8000 'New display' '" .. safe .. "'")
        end
      end
    end

    function _G.hlMonitorReconcile()
      local snap = snapshot()
      local p = pick(snap)
      if not p then return end
      apply(snap, p)
      announce(snap)
    end
  '';

  # Subscriptions + first pass.  Idempotent: safe to call more than once.
  #
  # NOTE: the Lua VM is wiped by `hyprctl reload`, taking these subscriptions
  # with it, so after a `nixos-rebuild switch` reconciliation is dead until
  # relogin.  If Hyprland re-executes the Lua config on reload, calling
  # `hlMonitorInit()` from the top level of the config (instead of only from
  # the `hyprland.start` handler) fixes that — the _G guard below resets
  # along with the VM, so re-subscribing is correct rather than duplicated.
  init = ''
    ${setup}

    function _G.hlMonitorInit()
      if _G.__hlMonInit then return end
      _G.__hlMonInit = true

      -- Debounced: re-run shortly after a topology change so Hyprland has
      -- settled.  hl.timer/hl.on hand back GC-managed handles — drop the
      -- reference and the subscription dies silently, hence hlKeep.
      local function schedule()
        hlKeep(hl.timer(function() _G.hlMonitorReconcile() end,
                        { timeout = 300, type = "oneshot" }))
      end

      hlKeep(hl.on("monitor.added",   schedule))
      hlKeep(hl.on("monitor.removed", schedule))
      hlKeep(hl.timer(function() _G.hlMonitorReconcile() end,
                      { timeout = 500, type = "oneshot" }))
    end

    _G.hlMonitorInit()
  '';
in {
  inherit setup init;
}
