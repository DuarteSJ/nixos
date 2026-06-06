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

  inline = lib.generators.mkLuaInline;

  monitorManager = import ./monitor-manager.nix {
    inherit pkgs laptop workspaces preferExternal;
    inherit (vars) gaps;
    themeName = config.colorScheme.slug;
    wallpapersPath = vars.paths.wallpapers;
  };

  # ------------------------------------------------------------------
  # Scripts
  # ------------------------------------------------------------------

  rofi-launcher = pkgs.writeShellScript "rofi-launcher" ''
    set -euo pipefail
    rofi -show drun
  '';

  rofi-powermenu = pkgs.writeShellScript "rofi-powermenu" ''
    set -euo pipefail
    shutdown="⏻ shutdown"
    reboot=" reboot"
    lock=" lock"
    logout=" logout"
    suspend=" suspend"

    options="$lock\n$suspend\n$shutdown\n$reboot\n$logout"

    chosen=$(echo -e "$options" | rofi -dmenu -p "Power Menu") || exit 0

    case "$chosen" in
        "$shutdown") systemctl poweroff ;;
        "$reboot")   systemctl reboot ;;
        "$lock")     hyprlock ;;
        "$logout")   hyprctl dispatch 'hl.dsp.exit()' ;;
        "$suspend")  hyprlock & systemctl suspend ;;
    esac
  '';

  toggleWaybar = pkgs.writeShellScript "toggle-waybar" ''
    set -euo pipefail
    if pgrep waybar > /dev/null; then
      pkill waybar
    else
      waybar &
    fi
  '';

  toggleMic = pkgs.writeShellScript "toggle-mic" ''
    set -euo pipefail
    wpctl set-mute @DEFAULT_SOURCE@ toggle
    if wpctl get-volume @DEFAULT_SOURCE@ | grep -q "MUTED"; then
      dunstify "Mic Status" "Microphone is now muted"
    else
      dunstify "Mic Status" "Microphone is now unmuted"
    fi
  '';

  # ------------------------------------------------------------------
  # Lua config helpers
  # ------------------------------------------------------------------

  mkMonitor = m: {
    _args = [
      (
        {
          output =
            if m ? description
            then "desc:${m.description}"
            else m.name;
          mode = m.mode;
          position = m.position;
          scale = m.scale;
        }
        // lib.optionalAttrs ((m.transform or 0) != 0) {transform = m.transform;}
      )
    ];
  };

  modKey = key: inline ''mainMod .. " + ${key}"'';
  modShiftKey = key: inline ''mainMod .. " + SHIFT + ${key}"'';
  bareKey = key: inline ''"${key}"'';

  exec = cmd: inline ''hl.dsp.exec_cmd("${cmd}")'';
  focusDir = d: inline ''hl.dsp.focus({ direction = "${d}" })'';
  swapDir = d: inline ''hl.dsp.window.swap({ direction = "${d}" })'';
  focusWs = n: inline ''hl.dsp.focus({ workspace = ${toString n} })'';
  moveToWs = n: inline ''hl.dsp.window.move({ workspace = ${toString n} })'';
  moveToSpecial = s: inline ''hl.dsp.window.move({ workspace = "special:${s}" })'';
  toggleSpecial = s: inline ''hl.dsp.workspace.toggle_special("${s}")'';
  resizeBy = x: y: inline ''hl.dsp.window.resize({ x = ${toString x}, y = ${toString y}, relative = true })'';

  kb = key: dsp: {_args = [key dsp];};
  kbo = key: dsp: opts: {_args = [key dsp opts];};

  # 1..10 → keys 1..9,0; SUPER+N focus, SUPER+SHIFT+N move
  numWsBinds = lib.flatten (lib.genList (i: let
    n = i + 1;
    k =
      if n == 10
      then "0"
      else toString n;
  in [
    (kb (modKey k) (focusWs n))
    (kb (modShiftKey k) (moveToWs n))
  ]) 10);

  # a/s/d/f/g → workspaces 1..5
  letterWsBinds = lib.flatten (lib.imap1 (i: l: [
    (kb (modKey l) (focusWs i))
    (kb (modShiftKey l) (moveToWs i))
  ]) ["a" "s" "d" "f" "g"]);

  # ------------------------------------------------------------------
  # #1 Inline Lua bind actions (replaced shell scripts + /tmp state)
  # ------------------------------------------------------------------

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
            gaps_in  = on and 0 or ${toString (vars.gaps / 2)},
            gaps_out = on and 0 or ${toString vars.gaps},
            col = on
              and { active_border = "rgba(${base02}aa)", inactive_border = "rgba(${base02}aa)" }
              or  { active_border = { colors = {"rgba(${base0D}cc)", "rgba(${base0C}77)"}, angle = 45 }, inactive_border = "rgba(${base02}aa)" },
          },
          decoration = {
            rounding     = on and 0 or ${toString rounding},
            dim_inactive = on,
            dim_strength = on and 0.15 or 0.0,
          },
        })
        hl.exec_cmd(on and "pkill waybar" or "waybar")
      end
    end)()'';

  # Gap +/- : read live value with hl.get_config, clamp, write back.
  incGaps = inline ''
    function()
      local out = (hl.get_config("general.gaps_out") or 0) + 2
      hl.config({
        general    = { gaps_out = out, gaps_in = math.floor(out / 2) },
        decoration = { rounding = ${toString rounding} },
      })
    end'';
  decGaps = inline ''
    function()
      local out = (hl.get_config("general.gaps_out") or 0) - 2
      if out < 0 then out = 0 end
      hl.config({
        general    = { gaps_out = out, gaps_in = math.floor(out / 2) },
        decoration = { rounding = out > 0 and ${toString rounding} or 0 },
      })
    end'';

  # ------------------------------------------------------------------
  # #4 Computed bind tables — one data list, binds derived
  # ------------------------------------------------------------------

  # special workspaces: SUPER+key toggles, SUPER+SHIFT+key moves window there.
  specialWs = [
    {key = "comma"; name = "music";}
    {key = "M"; name = "messages";}
  ];
  specialBinds = lib.concatMap (s: [
    (kb (modKey s.key) (toggleSpecial s.name))
    (kb (modShiftKey s.key) (moveToSpecial s.name))
  ]) specialWs;

  # media / volume / brightness keys, derived from a {key, cmd, opts} list.
  mediaBinds = map (b: kbo (bareKey b.key) (exec b.cmd) b.opts) [
    {key = "XF86AudioRaiseVolume"; cmd = "wpctl set-volume @DEFAULT_SINK@ 0.05+"; opts = {locked = true; repeating = true;};}
    {key = "XF86AudioLowerVolume"; cmd = "wpctl set-volume @DEFAULT_SINK@ 0.05-"; opts = {locked = true; repeating = true;};}
    {key = "XF86AudioMicMute"; cmd = "${toggleMic}"; opts = {locked = true; repeating = true;};}
    {key = "XF86AudioMute"; cmd = "wpctl set-mute @DEFAULT_SINK@ toggle"; opts = {locked = true; repeating = true;};}
    {key = "XF86MonBrightnessUp"; cmd = "brightnessctl s 4%+"; opts = {locked = true; repeating = true;};}
    {key = "XF86MonBrightnessDown"; cmd = "brightnessctl s 4%-"; opts = {locked = true; repeating = true;};}
    {key = "XF86AudioNext"; cmd = "playerctl next"; opts = {locked = true;};}
    {key = "XF86AudioPause"; cmd = "playerctl play-pause"; opts = {locked = true;};}
    {key = "XF86AudioPlay"; cmd = "playerctl play-pause"; opts = {locked = true;};}
    {key = "XF86AudioPrev"; cmd = "playerctl previous"; opts = {locked = true;};}
  ];

  # ------------------------------------------------------------------
  # Startup handler body (#2 events + #5 reconcile + #6 night dim)
  # ------------------------------------------------------------------
  startupLua = ''
    hl.exec_cmd("waybar")

    ${monitorManager.setup}

    -- #6 Time-of-day window dimming (additive to the hyprsunset service, which
    -- only changes gamma/temperature).  pcall-guarded in case os.* is absent
    -- from the Lua sandbox; re-checked every 10 min via a repeat timer.
    local function applyNightDim()
      local h = tonumber(os.date("%H"))
      local night = (h >= 21 or h < 7)
      hl.config({ decoration = { dim_inactive = night, dim_strength = night and 0.15 or 0.0 } })
    end
    -- hlKeep (defined in monitorManager.setup above) anchors the returned
    -- handle so GC can't drop the subscription/timer mid-session.
    if pcall(applyNightDim) then
      hlKeep(hl.timer(applyNightDim, { timeout = 600000, type = "repeat" }))
    end

    -- #2 Event handler — notify when a window marks itself urgent.
    hlKeep(hl.on("window.urgent", function(win)
      local who = (win and win.class) or "A window"
      hl.exec_cmd("dunstify -u critical 'Attention' '" .. who .. " needs attention'")
    end))
  '';
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
            };
            dwindle = {
              preserve_split = true;
            };
            master = {new_status = "slave";};
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
      env = [
        {_args = ["HYPRCURSOR_THEME" vars.cursor.name];}
        {_args = ["HYPRCURSOR_SIZE" (toString vars.cursor.size)];}
      ];

      # ---------------------------------------------------------------
      # Gestures
      # ---------------------------------------------------------------
      gesture = [
        {_args = [{fingers = 3; direction = "horizontal"; action = "workspace";}];}
        {_args = [{fingers = 4; direction = "horizontal"; action = "move";}];}
        {_args = [{fingers = 3; direction = "vertical"; action = "special"; workspace_name = "music";}];}
        {_args = [{fingers = 4; direction = "vertical"; action = "special"; workspace_name = "messages";}];}
      ];

      # ---------------------------------------------------------------
      # Window rules
      # ---------------------------------------------------------------
      window_rule = [
        {_args = [{match = {class = "^(spotify)$";}; float = true;}];}
        {_args = [{match = {class = "^(spotify)$";}; center = true;}];}
        {_args = [{match = {class = "^(spotify)$";}; rounding = 10;}];}
        {_args = [{match = {class = "vesktop";}; border_size = 0;}];}
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
            ${startupLua}
            end'')
        ];
      };

      # ---------------------------------------------------------------
      # Keybindings
      # ---------------------------------------------------------------
      bind =
        [
          # Apps & window ops
          (kb (modKey "Q") (exec vars.terminal))
          (kb (modKey "C") (inline "hl.dsp.window.close()"))
          (kb (modKey "P") (inline "hl.dsp.window.pin()"))
          (kb (modKey "V") (inline ''hl.dsp.window.float({ action = "toggle" })''))
          (kb (modKey "E") (exec "${rofi-launcher}"))
          (kb (modKey "R") (inline "hl.dsp.window.pseudo()"))
          (kb (modKey "T") (inline ''hl.dsp.layout("togglesplit")''))

          # Focus h/j/k/l
          (kb (modKey "H") (focusDir "left"))
          (kb (modKey "L") (focusDir "right"))
          (kb (modKey "K") (focusDir "up"))
          (kb (modKey "J") (focusDir "down"))
        ]
        ++ numWsBinds
        ++ letterWsBinds
        ++ specialBinds # #4 generated special-workspace binds
        ++ mediaBinds # #4 generated media/volume/brightness binds
        ++ [
          # Misc execs
          (kb (modKey "B") (exec "${toggleWaybar}"))
          (kb (modKey "N") (exec "${toggleMic}"))
          (kb (modShiftKey "P") (exec "${rofi-powermenu}"))
          (kb (modShiftKey "N") (exec "switch-bg"))
          (kb (modKey "X") (exec "hyprshot -z -m region"))
          (kb (modShiftKey "X") (exec "screenrec"))
          (kb (modKey "slash") prodToggle) # #1 inline Lua closure

          # Swap windows
          (kb (modShiftKey "h") (swapDir "left"))
          (kb (modShiftKey "j") (swapDir "down"))
          (kb (modShiftKey "k") (swapDir "up"))
          (kb (modShiftKey "l") (swapDir "right"))

          # Resize
          (kb (modKey "Left") (resizeBy (-65) 0))
          (kb (modKey "Down") (resizeBy 0 65))
          (kb (modKey "Up") (resizeBy 0 (-65)))
          (kb (modKey "Right") (resizeBy 65 0))

          # Gaps (#1 inline Lua closures, locked + repeating)
          (kbo (modKey "minus") incGaps {locked = true; repeating = true;})
          (kbo (modKey "equal") decGaps {locked = true; repeating = true;})

          # Lid (bindl = locked)
          (kbo (bareKey "switch:on:Lid Switch") (exec "hyprlock & systemctl suspend") {locked = true;})

          # Mouse (bindm)
          (kbo (modKey "mouse:272") (inline "hl.dsp.window.drag()") {mouse = true;})
          (kbo (modKey "mouse:273") (inline "hl.dsp.window.resize()") {mouse = true;})
        ];
    };
  };
}
