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

  prodCommon = ''
    STATE_DIR=/tmp/hypr-prod-mode
    mkdir -p "$STATE_DIR"

    ACTIVE_BORDER='rgba(${base0D}cc) rgba(${base0C}77) 45deg'
    INACTIVE_BORDER='rgba(${base02}aa)'

    enable_animations()  { hyprctl keyword animations:enabled 0; touch "$STATE_DIR/animations"; }
    disable_animations() { hyprctl keyword animations:enabled 1; rm -f "$STATE_DIR/animations"; }

    enable_gaps() {
      hyprctl keyword general:gaps_in 0
      hyprctl keyword general:gaps_out 0
      hyprctl keyword decoration:rounding 0
      touch "$STATE_DIR/gaps"
    }
    disable_gaps() {
      hyprctl keyword general:gaps_in ${toString (vars.gaps / 2)}
      hyprctl keyword general:gaps_out ${toString vars.gaps}
      hyprctl keyword decoration:rounding ${toString rounding}
      rm -f "$STATE_DIR/gaps"
    }

    enable_borders() {
      hyprctl keyword general:col.active_border "$INACTIVE_BORDER"
      hyprctl keyword general:col.inactive_border "$INACTIVE_BORDER"
      touch "$STATE_DIR/borders"
    }
    disable_borders() {
      hyprctl keyword general:col.active_border "$ACTIVE_BORDER"
      hyprctl keyword general:col.inactive_border "$INACTIVE_BORDER"
      rm -f "$STATE_DIR/borders"
    }

    enable_waybar()  { ${pkgs.procps}/bin/pkill waybar 2>/dev/null || true; touch "$STATE_DIR/waybar"; }
    disable_waybar() { ${pkgs.procps}/bin/pgrep waybar >/dev/null || (${pkgs.waybar}/bin/waybar & disown); rm -f "$STATE_DIR/waybar"; }

    enable_dim() {
      hyprctl keyword decoration:dim_inactive true
      hyprctl keyword decoration:dim_strength 0.1
      touch "$STATE_DIR/dim"
    }
    disable_dim() {
      hyprctl keyword decoration:dim_inactive false
      rm -f "$STATE_DIR/dim"
    }

    any_on() { [ -n "$(ls -A "$STATE_DIR" 2>/dev/null)" ]; }
  '';

  productivityToggle = pkgs.writeShellScript "productivity-toggle" ''
    set -euo pipefail
    ${prodCommon}
    if any_on; then
      disable_animations; disable_gaps; disable_borders; disable_waybar; disable_dim
    else
      enable_animations; enable_gaps; enable_borders; enable_waybar; enable_dim
    fi
  '';

  increase_gaps = pkgs.writeShellScript "increase-gaps" ''
    set -euo pipefail
    cur_out=$(hyprctl getoption general:gaps_out | awk '{print $3}')
    [[ "$cur_out" =~ ^-?[0-9]+$ ]] || exit 1

    new_out=$((cur_out + 2))
    new_in=$((new_out / 2))

    if [ "$new_in" -gt 0 ]; then
      hyprctl keyword decoration:rounding ${toString rounding}
    fi

    hyprctl keyword general:gaps_out $new_out $new_out $new_out $new_out
    hyprctl keyword general:gaps_in  $new_in $new_in $new_in $new_in
  '';

  decrease_gaps = pkgs.writeShellScript "decrease-gaps" ''
    set -euo pipefail
    cur_out=$(hyprctl getoption general:gaps_out | awk '{print $3}')
    [[ "$cur_out" =~ ^-?[0-9]+$ ]] || exit 1

    new_out=$((cur_out - 2))
    if [ "$new_out" -lt 0 ]; then
      new_out=0
      hyprctl keyword decoration:rounding 0
    fi

    new_in=$((new_out / 2))

    hyprctl keyword general:gaps_out $new_out $new_out $new_out $new_out
    hyprctl keyword general:gaps_in  $new_in $new_in $new_in $new_in
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
              hl.exec_cmd("waybar")
              hl.exec_cmd("${monitorManager}")
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
        ++ [
          # Special workspaces
          (kb (modKey "comma") (toggleSpecial "music"))
          (kb (modShiftKey "comma") (moveToSpecial "music"))
          (kb (modKey "M") (toggleSpecial "messages"))
          (kb (modShiftKey "M") (moveToSpecial "messages"))

          # Misc execs
          (kb (modKey "B") (exec "${toggleWaybar}"))
          (kb (modKey "N") (exec "${toggleMic}"))
          (kb (modShiftKey "P") (exec "${rofi-powermenu}"))
          (kb (modShiftKey "N") (exec "switch-bg"))
          (kb (modKey "X") (exec "hyprshot -z -m region"))
          (kb (modShiftKey "X") (exec "screenrec"))
          (kb (modKey "slash") (exec "${productivityToggle}"))

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

          # Volume / brightness / gaps (bindel = locked + repeating)
          (kbo (bareKey "XF86AudioRaiseVolume") (exec "wpctl set-volume @DEFAULT_SINK@ 0.05+") {locked = true; repeating = true;})
          (kbo (bareKey "XF86AudioLowerVolume") (exec "wpctl set-volume @DEFAULT_SINK@ 0.05-") {locked = true; repeating = true;})
          (kbo (bareKey "XF86AudioMicMute") (exec "${toggleMic}") {locked = true; repeating = true;})
          (kbo (bareKey "XF86AudioMute") (exec "wpctl set-mute @DEFAULT_SINK@ toggle") {locked = true; repeating = true;})
          (kbo (bareKey "XF86MonBrightnessUp") (exec "brightnessctl s 4%+") {locked = true; repeating = true;})
          (kbo (bareKey "XF86MonBrightnessDown") (exec "brightnessctl s 4%-") {locked = true; repeating = true;})
          (kbo (modKey "minus") (exec "${increase_gaps}") {locked = true; repeating = true;})
          (kbo (modKey "equal") (exec "${decrease_gaps}") {locked = true; repeating = true;})

          # Media + lid (bindl = locked)
          (kbo (bareKey "XF86AudioNext") (exec "playerctl next") {locked = true;})
          (kbo (bareKey "XF86AudioPause") (exec "playerctl play-pause") {locked = true;})
          (kbo (bareKey "XF86AudioPlay") (exec "playerctl play-pause") {locked = true;})
          (kbo (bareKey "XF86AudioPrev") (exec "playerctl previous") {locked = true;})
          (kbo (bareKey "switch:on:Lid Switch") (exec "hyprlock & systemctl suspend") {locked = true;})

          # Mouse (bindm)
          (kbo (modKey "mouse:272") (inline "hl.dsp.window.drag()") {mouse = true;})
          (kbo (modKey "mouse:273") (inline "hl.dsp.window.resize()") {mouse = true;})
        ];
    };
  };
}
