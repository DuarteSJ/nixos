{
  config,
  osConfig,
  pkgs,
  lib,
  notifyPkg,
  ...
}: let
  inherit (config) monitors;
  inherit (monitors) outputs profiles announceUnknown;
  inherit (config) vars;
  inherit (config.colorScheme.palette) base0D base0C base02;

  toLua = lib.generators.toLua {multiline = false;};

  # The look a config load starts from, and what focus mode (prodToggle in
  # lua-actions.nix) restores when switched off.  Rendered into the static
  # `config` block below AND handed to lua-actions as a Lua table, so the two
  # can't drift.  Everything focus mode or the gap keys touch must be here.
  baseline = {
    animations.enabled = true;
    general = {
      gaps_in = vars.gapsInner;
      gaps_out = vars.gapsOuter;
      col = {
        active_border = {
          colors = ["rgba(${base0D}cc)" "rgba(${base0C}77)"];
          angle = 45;
        };
        inactive_border = "rgba(${base02}aa)";
      };
    };
    decoration = {
      inherit (vars) rounding;
      dim_inactive = false;
    };
  };

  # Animation entries share enabled/speed/bezier; override per-leaf via attrs.
  mkAnim = attrs: {
    _args = [
      ({
          enabled = true;
          speed = 1;
          bezier = "snap";
        }
        // attrs)
    ];
  };

  # ------------------------------------------------------------------
  # Sub-modules
  # ------------------------------------------------------------------
  helpers = import ./lib.nix {inherit lib;};
  inherit (helpers) inline mkMonitor specOf;

  scripts = import ./scripts.nix {inherit pkgs notifyPkg;};

  monitorManager = import ./monitor-manager.nix {
    inherit lib specOf outputs profiles announceUnknown;
  };

  wallpaper = import ./wallpaper.nix {
    inherit pkgs notifyPkg;
    hyprland = osConfig.programs.hyprland.package;
    themeName = config.colorScheme.slug;
    wallpapersPath = vars.paths.wallpapers;
  };

  # Quickshell IPC prefix, absolute so it doesn't depend on Hyprland's PATH.
  qsIpc = "${lib.getExe' pkgs.quickshell "qs"} -c shell ipc call";

  luaActions = import ./lua-actions.nix {
    inherit lib inline baseline base02 monitorManager qsIpc;
  };

  bind = import ./keybinds.nix {
    inherit lib helpers scripts luaActions vars pkgs qsIpc;
    wallpaperPkg = wallpaper.package;
  };

  # Shared head of `extraConfig`.
  #
  # keep(): hl.on / hl.timer return GC-managed handles; if the Lua handle is
  # collected, Hyprland drops the subscription and the callback silently
  # stops firing.  keep() anchors one in a global.  Local: every topLevel
  # below is in the same chunk, so they all see it.
  #
  # shq() / notify(): GLOBALS, because bind actions are rendered into
  # `settings`, i.e. before this prelude, and can only reach them at call
  # time through _G.  hl.exec_cmd runs its string through `sh -c`, so any
  # text that isn't a literal must go through shq(): POSIX single quoting,
  # which passes every byte through unchanged.  (The `'''` below is Nix's
  # escape for two quote characters: the Lua reads "'\\''".)
  #   notify({ r = "layout", t = 1500, u = "low" }, title, body)
  # Each opts key becomes the `notify` flag of the same letter.
  handlesPrelude = ''
    _G.__hlHandles = _G.__hlHandles or {}
    local function keep(h) _G.__hlHandles[#_G.__hlHandles + 1] = h; return h end

    function _G.shq(s)
      return "'" .. (tostring(s):gsub("'", "'\\'''")) .. "'"
    end

    function _G.notify(opts, title, body)
      local cmd, keys = { ${toLua (lib.getExe notifyPkg)} }, {}
      for k in pairs(opts or {}) do keys[#keys + 1] = k end
      table.sort(keys)
      for _, k in ipairs(keys) do
        cmd[#cmd + 1] = "-" .. k .. " " .. shq(opts[k])
      end
      -- `--`: a title/body starting with "-" (e.g. an app-controlled window
      -- class) must not be read as a notify-send option.
      cmd[#cmd + 1] = "--"
      cmd[#cmd + 1] = shq(title)
      if body ~= nil then cmd[#cmd + 1] = shq(body) end
      hl.exec_cmd(table.concat(cmd, " "))
    end
  '';

  # Runs once per config load, after every topLevel has defined its pieces.
  # Monitors are not up yet while the config is first parsed, hence the
  # delay.  ONE timer, so the order is the order of the lines, not a race
  # between timeouts:
  #   1. monitor profile match (geometry/workspaces/disables; also arms the
  #      monitor manager's settling-window close),
  #   2. wallpapers for whatever is live after that,
  #   3. a load reset prodToggle and the config to baseline; bring the bar's
  #      focus-mode hide in line (harmless before Quickshell is up).
  startup = ''
    keep(hl.timer(function()
      _G.hlMonitorFirstPass()
      _G.hlWallpapers()
      hl.exec_cmd("${qsIpc} bar focusOff")
    end, { timeout = 500, type = "oneshot" }))
  '';
in {
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      # Locals
      mainMod = {_var = "SUPER";};

      # ---------------------------------------------------------------
      # Monitors
      # ---------------------------------------------------------------
      # Static per-output geometry + a catch-all so an unconfigured display
      # lights up on its own (preferred mode, auto position).  The runtime
      # profile layer only overrides what a matched profile names.
      monitor =
        map mkMonitor (lib.attrValues outputs)
        ++ [
          {
            _args = [
              {
                output = "";
                mode = "preferred";
                position = "auto";
                scale = 1;
              }
            ];
          }
        ];

      # ---------------------------------------------------------------
      # Bulk config: general / decoration / dwindle / binds / misc / input.
      # Hyprland defaults are left implicit (a reload resets to them anyway).
      # Gaps, borders, rounding, dim and animations come from `baseline`.
      # ---------------------------------------------------------------
      config = {
        _args = [
          (lib.recursiveUpdate baseline {
            general.resize_on_border = true;
            decoration.blur.enabled = false;
            dwindle = {
              preserve_split = true;
            };
            # 0 = no scroll debounce, so every SUPER+scroll notch fires (and is
            # consumed by) the zoom bind instead of leaking to the focused app.
            binds = {scroll_event_delay = 0;};
            misc = {
              disable_hyprland_logo = true;
              disable_splash_rendering = true;
              force_default_wallpaper = 0;
            };
            input = {
              repeat_delay = 200;
              repeat_rate = 50;
              kb_layout = "uspt";
              touchpad.natural_scroll = true;
            };
          })
        ];
      };

      # ---------------------------------------------------------------
      # Bezier curves & animations
      # ---------------------------------------------------------------
      curve = [
        {
          _args = [
            "snap"
            {
              type = "bezier";
              points = [[0.1 0.9] [0.2 1.0]];
            }
          ];
        }
      ];

      animation = [
        (mkAnim {
          leaf = "windowsIn";
          style = "slide";
        })
        (mkAnim {
          leaf = "windowsOut";
          style = "slide";
        })
        (mkAnim {
          leaf = "windowsMove";
          style = "slide";
        })
        (mkAnim {
          leaf = "border";
          speed = 2;
        })
        (mkAnim {leaf = "fade";})
        (mkAnim {leaf = "workspaces";})
        (mkAnim {
          leaf = "specialWorkspace";
          style = "slidefadevert 90%";
        })
      ];

      # ---------------------------------------------------------------
      # Gestures
      # ---------------------------------------------------------------
      gesture = [
        {
          _args = [
            {
              fingers = 3;
              direction = "horizontal";
              action = "workspace";
            }
          ];
        }
        {
          _args = [
            {
              fingers = 4;
              direction = "horizontal";
              action = "move";
            }
          ];
        }
        {
          _args = [
            {
              fingers = 3;
              direction = "vertical";
              action = "special";
              workspace_name = "music";
            }
          ];
        }
        {
          _args = [
            {
              fingers = 2;
              direction = "pinch";
              mods = "SUPER";
              action = "cursorZoom";
              zoom_level = 1;
              mode = "live";
            }
          ];
        }
      ];

      # ---------------------------------------------------------------
      # Window rules
      # ---------------------------------------------------------------
      # Quickshell drawers attached to the bar animate themselves (they grow out of the
      # bar); Hyprland's own layer fade would fight it.
      layer_rule = [
        {
          _args = [
            {
              match = {namespace = "^qs-attached$";};
              no_anim = true;
            }
          ];
        }
      ];

      window_rule = [
        # Spotify reports its class as lowercase "spotify" (verified against
        # a live window via `hyprctl clients`); the first letter is bracketed
        # in case a future build capitalises it.  One rule, several effects.
        {
          _args = [
            {
              name = "spotify-panel";
              match = {class = "^[Ss]potify$";};
              float = true;
              size = "55% 65%";
              center = true;
              # Deliberately heavy, unlike vars.rounding: this is a floating
              # media panel, not a tiled surface.  One site, so no token.
              rounding = 20;
            }
          ];
        }
        # Deny focus to XWayland phantom surfaces so
        # they can't steal focus from the active window.
        {
          _args = [
            {
              match = {
                class = "^$";
                title = "^$";
                xwayland = true;
                float = true;
                fullscreen = false;
                pin = false;
              };
              no_focus = true;
            }
          ];
        }
        # Keep Megabonk running on a hidden workspace: without frame
        # callbacks it blocks on vsync and freezes until shown again.
        {
          _args = [
            {
              match = {class = "^Megabonk\\.x86_64$";};
              render_unfocused = true;
            }
          ];
        }
      ];

      # ---------------------------------------------------------------
      # Workspace rules (special workspaces only;
      # regular ones pinned at runtime by monitor-manager)
      # ---------------------------------------------------------------
      workspace_rule = [
        {
          _args = [
            {
              workspace = "special:music";
              on_created_empty = "spotify";
            }
          ];
        }
      ];

      # ---------------------------------------------------------------
      # Keybindings (see ./keybinds.nix)
      # ---------------------------------------------------------------
      inherit bind;
    };

    # Raw Lua appended after `settings`, so the static monitor rules above are
    # already applied when this runs.  Home Manager re-emits the whole file on
    # rebuild and Hyprland re-executes it on every reload, which is what makes
    # profile matching here self-healing.
    extraConfig = lib.concatStringsSep "\n" [
      handlesPrelude
      monitorManager.topLevel
      wallpaper.setup
      luaActions.topLevel
      startup
    ];
  };
}
