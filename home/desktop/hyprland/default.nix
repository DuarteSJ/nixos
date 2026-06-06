{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (config) monitors;
  inherit (monitors) laptop externals workspaces preferExternal;
  inherit (config) vars;
  inherit (vars) rounding;
  inherit (config.colorScheme.palette) base0D base0C base02;

  # ------------------------------------------------------------------
  # Sub-modules
  # ------------------------------------------------------------------
  helpers = import ./lib.nix {inherit lib;};
  inherit (helpers) inline mkMonitor;

  scripts = import ./scripts.nix {inherit pkgs;};

  monitorManager = import ./monitor-manager.nix {
    inherit pkgs laptop workspaces preferExternal;
    inherit (vars) gaps;
    themeName = config.colorScheme.slug;
    wallpapersPath = vars.paths.wallpapers;
  };

  luaActions = import ./lua-actions.nix {
    inherit inline vars rounding base02 base0D base0C monitorManager;
  };

  bind = import ./keybinds.nix {
    inherit lib helpers scripts luaActions vars;
  };
in {
  wayland.windowManager.hyprland = {
    enable = true;
    settings = with config.colorScheme.palette; {
      # Locals
      mainMod = {_var = "SUPER";};

      # ---------------------------------------------------------------
      # Monitors
      # ---------------------------------------------------------------
      monitor =
        [(mkMonitor laptop)]
        ++ map mkMonitor externals
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
      # Bulk config: general / decoration / dwindle / master / misc / input / animations.enabled
      # ---------------------------------------------------------------
      config = {
        _args = [
          {
            general = {
              gaps_in = vars.gaps / 2;
              gaps_out = vars.gaps;
              border_size = 1;
              col = {
                active_border = {
                  colors = ["rgba(${base0D}cc)" "rgba(${base0C}77)"];
                  angle = 45;
                };
                inactive_border = "rgba(${base02}aa)";
              };
              resize_on_border = true;
              allow_tearing = false;
              layout = "dwindle";
            };
            decoration = {
              inherit rounding;
              inactive_opacity = 1;
              active_opacity = 1;
              blur.enabled = false;
            };
            dwindle = {
              preserve_split = true;
            };
            master = {new_status = "slave";};
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
              follow_mouse = 1;
              sensitivity = 0;
              kb_layout = "us,pt";
              kb_options = "grp:win_space_toggle";
              touchpad.natural_scroll = true;
            };
            animations = {enabled = true;};
          }
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
        {_args = [{leaf = "windowsIn"; enabled = true; speed = 1; bezier = "snap"; style = "slide";}];}
        {_args = [{leaf = "windowsOut"; enabled = true; speed = 1; bezier = "snap"; style = "slide";}];}
        {_args = [{leaf = "windowsMove"; enabled = true; speed = 1; bezier = "snap"; style = "slide";}];}
        {_args = [{leaf = "border"; enabled = true; speed = 2; bezier = "snap";}];}
        {_args = [{leaf = "fade"; enabled = true; speed = 1; bezier = "snap";}];}
        {_args = [{leaf = "workspaces"; enabled = true; speed = 1; bezier = "snap";}];}
        {_args = [{leaf = "specialWorkspace"; enabled = true; speed = 1; bezier = "snap"; style = "slidefadevert 90%";}];}
      ];

      # ---------------------------------------------------------------
      # Env
      # ---------------------------------------------------------------
      # Cursor env (HYPRCURSOR_THEME/SIZE) set by home.pointerCursor (see vars.nix).
      env = [
      ];

      # ---------------------------------------------------------------
      # Gestures
      # ---------------------------------------------------------------
      gesture = [
        {_args = [{fingers = 3; direction = "horizontal"; action = "workspace";}];}
        {_args = [{fingers = 4; direction = "horizontal"; action = "move";}];}
        {_args = [{fingers = 3; direction = "vertical"; action = "special"; workspace_name = "music";}];}
        {_args = [{fingers = 4; direction = "vertical"; action = "special"; workspace_name = "messages";}];}
        {_args = [{fingers = 2; direction = "pinch"; mods = "SUPER"; action = "cursorZoom"; zoom_level = 1; mode = "live";}];}
      ];

      # ---------------------------------------------------------------
      # Window rules
      # ---------------------------------------------------------------
      window_rule = [
        {_args = [{match = {class = "^(Spotify)$";}; float = true;}];}
        {_args = [{match = {class = "^(Spotify)$";}; size = "60% 55%";}];}
        {_args = [{match = {class = "^(Spotify)$";}; center = true;}];}
        {_args = [{match = {class = "^(Spotify)$";}; rounding = 20;}];}
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
      ];

      # ---------------------------------------------------------------
      # Workspace rules (special workspaces only;
      # regular ones pinned at runtime by monitor-manager)
      # ---------------------------------------------------------------
      workspace_rule = [
        {_args = [{workspace = "special:music"; on_created_empty = "spotify";}];}
        {_args = [{workspace = "special:messages"; on_created_empty = "beeper";}];}
      ];

      # ---------------------------------------------------------------
      # Startup (exec-once equivalent)
      # ---------------------------------------------------------------
      on = {
        _args = [
          "hyprland.start"
          (inline ''
            function()
            ${luaActions.startupLua}
            end'')
        ];
      };

      # ---------------------------------------------------------------
      # Keybindings (see ./keybinds.nix)
      # ---------------------------------------------------------------
      inherit bind;
    };
  };
}
