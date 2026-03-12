{ config, pkgs, lib, ... }: let

  cfg     = config.monitors;
  laptop  = cfg.laptop;
  externals = cfg.external;

  # ------------------------------------------------------------------
  # Helpers
  # ------------------------------------------------------------------

  # Render a monitor line for hyprland.settings.monitor
  monitorLine = m:
    "${m.name}, ${m.mode}, ${m.position}, ${m.scale}"
    + (if m.transform != 0 then ", transform, ${toString m.transform}" else "");

  # Render the enable command for a monitor (used in scripts)
  monitorEnableCmd = m:
    "hyprctl keyword monitor '${monitorLine m}'";

  rounding = 2;

  # ------------------------------------------------------------------
  # Scripts
  # ------------------------------------------------------------------

  rofi-launcher = pkgs.writeShellScript "rofi-launcher" ''
    rofi -show drun
  '';

  rofi-powermenu = pkgs.writeShellScript "rofi-powermenu" ''
    # Options
    shutdown="⏻ shutdown"
    reboot=" reboot"
    lock=" lock"
    logout=" logout"
    suspend=" suspend"

    # Variable
    options="$lock\n$suspend\n$shutdown\n$reboot\n$logout"

    # Show rofi menu
    chosen=$(echo -e "$options" | rofi -dmenu -p "Power Menu")

    case $chosen in
        $shutdown)
            systemctl poweroff
            ;;
        $reboot)
            systemctl reboot
            ;;
        $lock)
            hyprlock
            ;;
        $logout)
            hyprctl dispatch exit
            ;;
        $suspend)
            hyprlock &
            systemctl suspend
            ;;
    esac
  '';

  toggleWaybar = pkgs.writeShellScript "toggle-waybar" ''
    if pgrep waybar > /dev/null; then
      pkill waybar
    else
      waybar &
    fi
  '';

  toggleMic = pkgs.writeShellScript "toggle-mic" ''
    wpctl set-mute @DEFAULT_SOURCE@ toggle
    if wpctl get-volume @DEFAULT_SOURCE@ | grep -q "MUTED"; then
      dunstify "Mic Status" "Microphone is now muted"
    else
      dunstify "Mic Status" "Microphone is now unmuted"
    fi
  '';

  toggleAnimations = pkgs.writeShellScript "toggle-animations" ''
    val=$(hyprctl getoption animations:enabled | awk '/int:/ {print $2}')
    hyprctl keyword animations:enabled $((1 - val))
  '';

  increase_gaps = pkgs.writeShellScript "increase-gaps" ''
    cur=$(hyprctl getoption general:gaps_in | awk '{print $3}')
    [ "$cur" -eq 0 ] && hyprctl keyword decoration:rounding ${toString rounding}
    n=$((cur + 2))
    hyprctl keyword general:gaps_in  $n $n $n $n
    hyprctl keyword general:gaps_out $n $n $n $n
  '';

  decrease_gaps = pkgs.writeShellScript "decrease-gaps" ''
    cur=$(hyprctl getoption general:gaps_in | awk '{print $3}')
    n=$((cur - 2))
    if [ "$n" -lt 0 ]; then
      n=0
      hyprctl keyword decoration:rounding 0
    fi
    hyprctl keyword general:gaps_in  $n $n $n $n
    hyprctl keyword general:gaps_out $n $n $n $n
  '';

  # ------------------------------------------------------------------
  # monitor-manager
  #
  # Single long-running script (exec-once) that owns all runtime
  # monitor logic:
  #
  #   • Applies the correct state at startup (handles "already plugged
  #     in when Hyprland starts" and "laptop only" equally).
  #   • Reacts to monitoradded / monitorremoved socket events.
  #   • Optionally disables the laptop panel when externals are present
  #     (controlled by monitors.disableLaptopWhenExternal).
  #   • Sets wallpapers via hyprpaper IPC for every active monitor,
  #     replacing the separate systemd service in hyprpaper.nix.
  #
  # Shell-level constants are injected from Nix so this script has no
  # dependency on hyprctl for config lookups — it only uses hyprctl to
  # issue commands.
  # ------------------------------------------------------------------

  # Build the wallpaper-setting fragment for one monitor.
  # Picks the first image found in ~/Pictures/wallpapers/<theme>/<orientation>/
  wallpaperBlock = m: let
    dir = if m.transform == 1 || m.transform == 3 then "vertical" else "horizontal";
  in ''
    set_wallpaper "${m.name}" "${dir}"
  '';

  monitorManager = pkgs.writeShellScript "monitor-manager" ''
    LAPTOP="${laptop.name}"
    LAPTOP_ENABLE="${monitorEnableCmd laptop}"
    LAPTOP_DISABLE="hyprctl keyword monitor ${laptop.name},disable"
    DISABLE_WHEN_EXTERNAL="${if cfg.disableLaptopWhenExternal then "1" else "0"}"

    # Known external monitors: "name|enable-cmd" pairs, newline-separated.
    EXTERNALS="${builtins.concatStringsSep "\n" (map (m: "${m.name}|${monitorEnableCmd m}") externals)}"

    THEME="${lib.toLower config.colorScheme.name}"
    WALLPAPER_BASE="$HOME/Pictures/wallpapers/$THEME"

    # ----------------------------------------------------------------
    # Wallpaper helper
    # ----------------------------------------------------------------
    set_wallpaper() {
      local monitor="$1" orientation="$2"
      local dir="$WALLPAPER_BASE/$orientation"
      local wp
      wp=$(${pkgs.findutils}/bin/find "$dir" -maxdepth 1 -type f \
             \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) \
           | ${pkgs.coreutils}/bin/sort -V | ${pkgs.coreutils}/bin/head -n1)
      if [[ -n "$wp" ]]; then
        hyprctl hyprpaper preload "$wp"   2>/dev/null
        hyprctl hyprpaper wallpaper "$monitor,$wp" 2>/dev/null
      fi
    }

    # ----------------------------------------------------------------
    # Query helpers
    # ----------------------------------------------------------------
    connected_monitors() {
      hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[].name'
    }

    has_external() {
      connected_monitors | grep -qvF "$LAPTOP"
    }

    # ----------------------------------------------------------------
    # Apply correct monitor state (idempotent, call any time)
    # ----------------------------------------------------------------
    apply_state() {
      local connected
      connected=$(connected_monitors)

      # Re-enable any known external that is connected but currently
      # not active (e.g. after a Hyprland restart with it plugged in).
      while IFS='|' read -r name cmd; do
        [[ -z "$name" ]] && continue
        if echo "$connected" | grep -qF "$name"; then
          eval "$cmd"
        fi
      done <<< "$EXTERNALS"

      # Laptop visibility
      if [[ "$DISABLE_WHEN_EXTERNAL" == "1" ]]; then
        if has_external; then
          eval "$LAPTOP_DISABLE"
        else
          eval "$LAPTOP_ENABLE"
        fi
      fi

      # Set wallpapers for every active monitor
      set_wallpaper "$LAPTOP" "horizontal"
      ${builtins.concatStringsSep "\n      " (map wallpaperBlock externals)}
    }

    # ----------------------------------------------------------------
    # Wait for Hyprland socket and hyprpaper to be ready
    # ----------------------------------------------------------------
    until [[ -S "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" ]]; do
      sleep 0.2
    done
    until hyprctl hyprpaper listloaded >/dev/null 2>&1; do
      sleep 0.2
    done

    apply_state

    # ----------------------------------------------------------------
    # Event loop
    # ----------------------------------------------------------------
    ${pkgs.socat}/bin/socat - \
      "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" \
    | while IFS= read -r line; do
        event="${"$"}{line%%>>*}"
        data="${"$"}{line##*>>}"
        case "$event" in
          monitoradded)
            # Find and apply the config for this specific monitor
            while IFS='|' read -r name cmd; do
              [[ "$name" == "$data" ]] && eval "$cmd" && break
            done <<< "$EXTERNALS"
            # Disable laptop if needed
            if [[ "$DISABLE_WHEN_EXTERNAL" == "1" ]] && [[ "$data" != "$LAPTOP" ]]; then
              eval "$LAPTOP_DISABLE"
            fi
            # Wallpaper for the new monitor
            ${builtins.concatStringsSep "\n            " (map (m: ''
              [[ "$data" == "${m.name}" ]] && set_wallpaper "${m.name}" "${if m.transform == 1 || m.transform == 3 then "vertical" else "horizontal"}"
            '') externals)}
            ;;
          monitorremoved)
            if [[ "$data" != "$LAPTOP" ]] && [[ "$DISABLE_WHEN_EXTERNAL" == "1" ]]; then
              sleep 0.3   # let hyprctl monitors reflect the removal
              has_external || eval "$LAPTOP_ENABLE"
            fi
            ;;
        esac
      done
  '';

  # ------------------------------------------------------------------
  # Workspace rules derived from monitor config
  # ------------------------------------------------------------------
  workspaceRules =
    (map (ws: "${toString ws}, monitor:${laptop.name}") laptop.workspaces)
    ++ (builtins.concatMap
          (m: map (ws: "${toString ws}, monitor:${m.name}") m.workspaces)
          externals);

  # ------------------------------------------------------------------
  # Window rule helpers (unchanged from original)
  # ------------------------------------------------------------------
  primaryMonitor = if externals != [] then builtins.head externals else laptop;

  parseMode = mode: let
    res   = builtins.head (builtins.split "@" mode);
    parts = builtins.split "x" res;
  in {
    width  = builtins.fromJSON (builtins.elemAt parts 0);
    height = builtins.fromJSON (builtins.elemAt parts 2);
  };

  rawDims     = parseMode primaryMonitor.mode;
  monitorDims = if primaryMonitor.transform == 1 || primaryMonitor.transform == 3
                then { width = rawDims.height; height = rawDims.width; }
                else rawDims;

  spotifyW = toString (monitorDims.width  * 65 / 100);
  spotifyH = toString (monitorDims.height * 63 / 100);
  cavaW    = toString (monitorDims.width  - 30);
  cavaY    = toString (monitorDims.height - 181 - 2);

in {
  wayland.windowManager.hyprland = {
    enable = true;
    settings = with config.colorScheme.palette; {

      # ---------------------------------------------------------------
      # Monitors
      #
      # Declare every known monitor with its preferred config.
      # The catch-all rule at the end makes any unknown monitor
      # (e.g. a borrowed projector) work automatically.
      # The laptop is always listed as enabled here — the monitor-manager
      # script handles disabling it at runtime when externals are present.
      # ---------------------------------------------------------------
      monitor =
        [ (monitorLine laptop) ]
        ++ (map monitorLine externals)
        ++ [ ", preferred, auto, 1" ];   # catch-all for unknown displays

      exec-once = [
        "waybar &"
        "${monitorManager}"
      ];

      env = [
        "HYPRCURSOR_THEME,Nordzy-cursors"
        "HYPRCURSOR_SIZE,26"
      ];

      general = {
        gaps_in  = 2;
        gaps_out = 4;
        border_size = 1;
        "col.active_border"   = "rgba(${base0D}cc) rgba(${base0C}77) 45deg";
        "col.inactive_border" = "rgba(${base02}aa)";
        resize_on_border = true;
        allow_tearing    = false;
        layout           = "dwindle";
      };

      decoration = {
        rounding         = rounding;
        inactive_opacity = 1;
        active_opacity   = 1;
        shadow.enabled   = false;
        shadow.range     = 96;
        shadow.render_power = 3;
        shadow.color     = "rgba(${base00}ff)";
        blur.enabled     = false;
        blur.size        = 3;
        blur.passes      = 1;
        blur.vibrancy    = 0.1696;
      };

      animations = {
        enabled = true;
        bezier  = [ "snap, 0.1, 0.9, 0.2, 1.0" ];
        animation = [
          "windowsIn, 1, 1, snap, slide"
          "windowsOut, 1, 1, snap, slide"
          "windowsMove, 1, 1, snap, slide"
          "border, 1, 2, snap"
          "fade, 1, 1, snap"
          "workspaces, 1, 1, snap"
          "specialWorkspace, 1, 1, snap, slidefadevert 90%"
        ];
      };

      dwindle = { pseudotile = true; preserve_split = true; };
      master  = { new_status = "slave"; };
      misc    = { disable_hyprland_logo = true; };

      input = {
        repeat_delay = 200;
        repeat_rate  = 50;
        follow_mouse = 1;
        sensitivity  = 0;
        kb_layout    = "us,pt";
        kb_options   = "grp:win_space_toggle";
        touchpad.natural_scroll = true;
      };

      gestures.workspace_swipe_forever = true;

      "$mainMod" = "SUPER";

      bind = [
        "$mainMod, Q, exec, alacritty"
        "$mainMod, C, killactive,"
        "$mainMod, P, exec, hyprctl dispatch pin"
        "$mainMod, V, togglefloating,"
        "$mainMod, E, exec, ${rofi-launcher}"
        "$mainMod, R, pseudo,"
        "$mainMod, T, togglesplit,"

        "$mainMod, H, movefocus, l"
        "$mainMod, L, movefocus, r"
        "$mainMod, K, movefocus, u"
        "$mainMod, J, movefocus, d"

        "$mainMod, 1, workspace, 1"  "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"  "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"  "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"  "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"  "$mainMod, 0, workspace, 10"

        "$mainMod, A, workspace, 1"  "$mainMod, S, workspace, 2"
        "$mainMod, D, workspace, 3"  "$mainMod, F, workspace, 4"
        "$mainMod, G, workspace, 5"

        "$mainMod SHIFT, 1, movetoworkspace, 1"  "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"  "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"  "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"  "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"  "$mainMod SHIFT, 0, movetoworkspace, 10"

        "$mainMod SHIFT, A, movetoworkspace, 1"  "$mainMod SHIFT, S, movetoworkspace, 2"
        "$mainMod SHIFT, D, movetoworkspace, 3"  "$mainMod SHIFT, F, movetoworkspace, 4"
        "$mainMod SHIFT, G, movetoworkspace, 5"

        "$mainMod, comma,       togglespecialworkspace, music"
        "$mainMod SHIFT, comma, movetoworkspace,        special:music"
        "$mainMod, M,           togglespecialworkspace, messages"
        "$mainMod SHIFT, M,     movetoworkspace,        special:messages"

        "$mainMod, B,        exec, ${toggleWaybar}"
        "$mainMod, N,        exec, ${toggleMic}"
        "$mainMod SHIFT, P,  exec, ${rofi-powermenu}"
        "$mainMod SHIFT, N,  exec, switch-bg"
        "$mainMod, X,        exec, screenshot"
        "$mainMod SHIFT, X,  exec, screenrec"
        "$mainMod, slash,    exec, ${toggleAnimations}"

        "$mainMod SHIFT, h, swapwindow, l"
        "$mainMod SHIFT, j, swapwindow, d"
        "$mainMod SHIFT, k, swapwindow, u"
        "$mainMod SHIFT, l, swapwindow, r"

        "$mainMod, Left,  resizeactive, -65 0"
        "$mainMod, Down,  resizeactive,  0 65"
        "$mainMod, Up,    resizeactive,  0 -65"
        "$mainMod, Right, resizeactive, 65 0"
      ];

      bindel = [
        ",XF86AudioRaiseVolume,  exec, wpctl set-volume @DEFAULT_SINK@ 0.05+"
        ",XF86AudioLowerVolume,  exec, wpctl set-volume @DEFAULT_SINK@ 0.05-"
        ",XF86AudioMicMute,      exec, ${toggleMic}"
        ",XF86AudioMute,         exec, wpctl set-mute @DEFAULT_SINK@ toggle"
        ",XF86MonBrightnessUp,   exec, brightnessctl s 4%+"
        ",XF86MonBrightnessDown, exec, brightnessctl s 4%-"
        "$mainMod, minus, exec, ${increase_gaps}"
        "$mainMod, equal, exec, ${decrease_gaps}"
      ];

      bindl = [
        ", XF86AudioNext,  exec, playerctl next"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioPlay,  exec, playerctl play-pause"
        ", XF86AudioPrev,  exec, playerctl previous"
        # Lid switch: always disable/enable the laptop panel directly.
        # This is separate from the hotplug logic — closing the lid should
        # blank the screen even when no external is connected.
        ", switch:on:Lid Switch,  exec, hyprlock &; systemctl suspend"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      windowrulev2 = [
        "float,                    class:^(spotify)$"
        "size ${spotifyW} ${spotifyH}, class:^(spotify)$"
        "center,                   class:^(spotify)$"
        "rounding 10,              class:^(spotify)$"

        "bordersize 0,             class:vesktop"

        "float,                    class:^(invis-cava)$"
        "size ${cavaW} 181,        class:^(invis-cava)$"
        "move 0 ${cavaY},          class:^(invis-cava)$"
        "noborder,                 class:^(invis-cava)$"
        "noanim,                   class:^(invis-cava)$"

        "nofocus, class:^$, title:^$, xwayland:1, floating:1, fullscreen:0, pinned:0"
      ];

      workspace = [
        "special:music,    on-created-empty:invis-cava & spotify"
        "special:messages, on-created-empty:beeper"
      ] ++ workspaceRules;
    };
  };
}
