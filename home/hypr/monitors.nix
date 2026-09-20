# Monitor schema + this machine's values.
#
# Model: an ordered list of profiles, kanshi-style.  The first profile whose
# `requires` are all present wins.  Matching is NON-exclusive: extra monitors
# that a profile doesn't mention never stop it from matching, and are never
# touched by it — they fall through to Hyprland's static catch-all `monitor`
# rule (preferred mode / auto position), so an unknown display lights up on
# its own.  The last profile must have `requires = []`, so "no profile
# matched" is unrepresentable.
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types;

  # ------------------------------------------------------------------
  # Selectors: usable anywhere an output nickname is accepted.  Resolved
  # at runtime in Lua against live `hl.get_monitors()`.
  # ------------------------------------------------------------------
  predicateSelectors = ["@anyExternal"];
  outputSelectors = ["@builtin" "@primaryExternal"];
  allSelectors = predicateSelectors ++ outputSelectors;

  outputType = types.submodule {
    options = {
      name = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Connector name (e.g. "eDP-1").  Use for outputs that never move
          between ports — in practice only the built-in panel.
        '';
      };
      description = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          EDID description prefix as reported in `hyprctl monitors -j`
          (.description).  Matched by prefix, so the same spec applies
          regardless of which port the monitor is plugged into.
          Example: "HP Inc. HP 25x CNK9050RDP"
        '';
      };
      builtin = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Marks the laptop panel.  Exactly one output must set this.  The
          builtin is treated as always physically present, so it is never a
          meaningful `requires` entry — use the "@builtin" selector to act
          on it.
        '';
      };

      mode = mkOption {
        type = types.str;
        default = "preferred";
        description = "e.g. 1920x1080@119.98, or 'preferred'.";
      };
      position = mkOption {
        type = types.str;
        default = "auto";
        description = "e.g. 1920x0, or 'auto'.";
      };
      scale = mkOption {
        type = types.numbers.positive;
        default = 1;
      };
      transform = mkOption {
        type = types.int;
        default = 0;
        description = "0 = normal, 1 = 90°, 2 = 180°, 3 = 270°.";
      };
    };
  };

  # Partial geometry override applied over an output's base spec.  null =
  # inherit whatever the output declares.
  overrideType = types.submodule {
    options = {
      mode = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      position = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      scale = mkOption {
        type = types.nullOr types.numbers.positive;
        default = null;
      };
      transform = mkOption {
        type = types.nullOr types.int;
        default = null;
      };
      mirror = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Output nickname or selector to mirror.";
      };
    };
  };

  profileType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Label, used in logs/notifications and assertion messages.";
      };

      requires = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          Output nicknames and/or predicate selectors that must ALL be
          present for this profile to match.  Extra monitors are ignored
          (non-exclusive matching), so plugging in a display you have never
          seen does not stop your known profiles from matching.
        '';
      };

      enable = mkOption {
        type = types.attrsOf overrideType;
        default = {};
        description = ''
          Outputs to explicitly enable, keyed by nickname or selector, with
          per-profile geometry overrides.  Only needed to override geometry
          or to undo a `disable` from another profile — a freshly connected
          monitor is already brought up by Hyprland's catch-all rule.
        '';
      };

      disable = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          Outputs to blank, by nickname or selector.  Applied LAST, after
          geometry and workspace moves, because moving a workspace
          re-triggers monitor reconfiguration and would otherwise undo an
          earlier disable.  Selectors resolving to nothing are skipped, so
          a profile can never blank a display it doesn't name.
        '';
      };

      workspaces = mkOption {
        type = types.attrsOf (types.listOf types.int);
        default = {};
        description = ''
          Workspace pinning: output nickname or selector -> workspace ids.
          Sets a workspace_rule (future) and moves the workspace if it is
          currently live elsewhere (present).
        '';
      };

      overflow = mkOption {
        type = types.listOf types.int;
        default = [];
        description = ''
          Workspaces handed round-robin to active monitors that no
          `workspaces` key named — i.e. displays with no profile entry.
          Lets an unrecognised monitor receive windows by default instead
          of coming up lit but empty.
        '';
      };
    };
  };

  cfg = config.monitors;

  nicknames = builtins.attrNames cfg.outputs;
  knownRefs = nicknames ++ allSelectors;
  outputRefs = nicknames ++ outputSelectors;

  # Every selector a profile mentions, tagged with the field it came from so
  # assertion messages point at the right place.
  refsOf = p:
    map (r: {
      inherit (p) name;
      field = "requires";
      ref = r;
      mustResolve = false;
    })
    p.requires
    ++ map (r: {
      inherit (p) name;
      field = "enable";
      ref = r;
      mustResolve = true;
    }) (builtins.attrNames p.enable)
    ++ map (r: {
      inherit (p) name;
      field = "disable";
      ref = r;
      mustResolve = true;
    })
    p.disable
    ++ map (r: {
      inherit (p) name;
      field = "workspaces";
      ref = r;
      mustResolve = true;
    }) (builtins.attrNames p.workspaces);

  allRefs = builtins.concatLists (map refsOf cfg.profiles);

  badRefs = builtins.filter (r: !(builtins.elem r.ref knownRefs)) allRefs;
  # Predicate selectors describe presence; they don't name an output, so they
  # can't be enabled/disabled/pinned.
  predicateMisuse =
    builtins.filter
    (r: r.mustResolve && !(builtins.elem r.ref outputRefs))
    allRefs;

  # A profile that disables something it requires flip-flops: the disable
  # removes the monitor from the live set, the profile stops matching, the
  # next reconcile picks a different profile and re-enables it.
  selfDisabling =
    builtins.filter
    (p: builtins.any (d: builtins.elem d p.requires) p.disable)
    cfg.profiles;

  builtinOutputs = builtins.filter (o: o.builtin) (builtins.attrValues cfg.outputs);
  unidentified =
    builtins.filter
    (n: cfg.outputs.${n}.name == null && cfg.outputs.${n}.description == null)
    nicknames;
in {
  options.monitors = {
    outputs = mkOption {
      type = types.attrsOf outputType;
      default = {};
      description = ''
        Known displays keyed by a short nickname, with their default
        geometry.  Profiles refer to them by nickname.
      '';
    };

    profiles = mkOption {
      type = types.listOf profileType;
      default = [];
      description = ''
        Ordered, first match wins.  The last entry must have
        `requires = []` so something always matches.
      '';
    };

    workspaces = mkOption {
      type = types.listOf types.int;
      default = [1 2 3 4];
      description = ''
        The workspace set shown as persistent buttons in waybar.  Profiles
        normally pin exactly this set to whichever output is primary.
      '';
    };

    announceUnknown = mkOption {
      type = types.bool;
      default = true;
      description = ''
        When an external is connected that no output nickname matches, send
        a notification containing its EDID description, ready to paste into
        `monitors.outputs`.  Fires once per description per session.
      '';
    };
  };

  # ------------------------------------------------------------------
  # This machine
  # ------------------------------------------------------------------
  config.monitors = {
    workspaces = [1 2 3 4];

    outputs = {
      panel = {
        name = "eDP-1";
        builtin = true;
        mode = "1920x1200@59.95";
        position = "0x0";
      };

      hp = {
        description = "HP Inc. HP 25x CNK9050RDP";
        mode = "1920x1080@119.98";
        position = "1920x0";
      };
    };

    # Ordered, first match wins.  Add named profiles above the two `auto-*`
    # fallbacks; never below them (the last one matches everything).
    profiles = [
      {
        name = "hp-docked";
        requires = ["hp"];
        enable.hp = {};
        workspaces.hp = cfg.workspaces;
        disable = ["@builtin"];
      }

      # ---- fallbacks ------------------------------------------------
      # Any external at all, known or not: it becomes primary, panel off.
      # Covers displays that have no profile of their own.
      {
        name = "auto-external";
        requires = ["@anyExternal"];
        workspaces."@primaryExternal" = cfg.workspaces;
        disable = ["@builtin"];
      }

      # Nothing but the panel.  `requires = []` => always matches, so this
      # must stay last.
      {
        name = "auto-solo";
        requires = [];
        enable."@builtin" = {};
        workspaces."@builtin" = cfg.workspaces;
      }
    ];
  };

  config.assertions = [
    {
      assertion = cfg.profiles == [] || (lib.last cfg.profiles).requires == [];
      message = ''
        monitors.profiles: the last profile must have `requires = []` so that
        some profile always matches.  Last profile is
        "${(lib.last cfg.profiles).name}" with requires =
        ${builtins.toJSON (lib.last cfg.profiles).requires}.
      '';
    }
    {
      assertion = cfg.outputs == {} || builtins.length builtinOutputs == 1;
      message = ''
        monitors.outputs: exactly one output must set `builtin = true`
        (found ${toString (builtins.length builtinOutputs)}).
      '';
    }
    {
      assertion = unidentified == [];
      message = ''
        monitors.outputs: these outputs set neither `name` nor
        `description`, so nothing can match them: ${toString unidentified}.
      '';
    }
    {
      assertion = badRefs == [];
      message = ''
        monitors.profiles: unknown output reference(s):
        ${lib.concatMapStringsSep "\n" (r: "  profile \"${r.name}\".${r.field}: \"${r.ref}\"") badRefs}
        Known: ${toString knownRefs}
      '';
    }
    {
      assertion = predicateMisuse == [];
      message = ''
        monitors.profiles: ${toString predicateSelectors} are presence
        predicates — valid only in `requires`, not as an output to act on:
        ${lib.concatMapStringsSep "\n" (r: "  profile \"${r.name}\".${r.field}: \"${r.ref}\"") predicateMisuse}
      '';
    }
    {
      assertion = selfDisabling == [];
      message = ''
        monitors.profiles: a profile must not `disable` an output it also
        `requires` — the disable makes the profile stop matching, which
        re-enables the output, which makes it match again (flip-flop).
        Offending profile(s): ${toString (map (p: p.name) selfDisabling)}
      '';
    }
  ];
}
