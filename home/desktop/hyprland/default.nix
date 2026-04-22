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

  # ------------------------------------------------------------------
  # Monitor lines for Hyprland's static `monitor` config
  # ------------------------------------------------------------------

  transformSuffix = m:
    lib.optionalString (m.transform != 0) ",transform,${toString m.transform}";

  # Laptop is matched by connector name (it doesn't move).
  laptopLine = "${laptop.name},${laptop.mode},${laptop.position},${laptop.scale}${transformSuffix laptop}";

  # Externals are matched by EDID description (port-agnostic).
  externalLine = e: "desc:${e.description},${e.mode},${e.position},${e.scale}${transformSuffix e}";

  monitorManager = import ./monitor-manager.nix {
    inherit pkgs laptop workspaces preferExternal;
    themeName = lib.toLower config.colorScheme.name;
    wallpapersPath = vars.paths.wallpapers;
  };

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
    # Get the current outer gap
    cur_out=$(hyprctl getoption general:gaps_out | awk '{print $3}')

    # Increment outer gap by 2
    new_out=$((cur_out + 2))

    # Set inner gap to half of outer
    new_in=$((new_out / 2))

    # Restore rounding whenever there is a gap (decrease_gaps zeros it at 0)
    if [ "$new_in" -gt 0 ]; then
      hyprctl keyword decoration:rounding ${toString rounding}
    fi

    # Apply the gaps
    hyprctl keyword general:gaps_out $new_out $new_out $new_out $new_out
    hyprctl keyword general:gaps_in  $new_in $new_in $new_in $new_in
  '';

  decrease_gaps = pkgs.writeShellScript "decrease-gaps" ''
    # Get current outer gap
    cur_out=$(hyprctl getoption general:gaps_out | awk '{print $3}')

    # Decrement outer gap by 2
    new_out=$((cur_out - 2))
    if [ "$new_out" -lt 0 ]; then
      new_out=0
      hyprctl keyword decoration:rounding 0
    fi

    # Inner gap is always half of outer
    new_in=$((new_out / 2))

    # Apply the gaps
    hyprctl keyword general:gaps_out $new_out $new_out $new_out $new_out
    hyprctl keyword general:gaps_in  $new_in $new_in $new_in $new_in
  '';
in {
  wayland.windowManager.hyprland = {
    enable = true;
    settings = with config.colorScheme.palette; {
      # ---------------------------------------------------------------
      # Monitors
      #
      # Laptop is matched by connector name; known externals by EDID
      # description (so the same spec follows the monitor across ports).
      # The trailing catch-all rule makes any unknown monitor — a
      # borrowed projector, a TV — work automatically with preferred
      # mode and auto position.
      # The laptop is always listed as enabled here; monitor-manager
      # disables it at runtime when preferExternal applies.
      # ---------------------------------------------------------------
      monitor =
        [laptopLine]
        ++ map externalLine externals
        ++ [",preferred,auto,1"];

      exec-once = [
        "waybar &"
        "${monitorManager}"
      ];

      env = [
        "HYPRCURSOR_THEME,${vars.cursor.name}"
        "HYPRCURSOR_SIZE,${toString vars.cursor.size}"
      ];

      general = {
        gaps_in = vars.gaps / 2;
        gaps_out = vars.gaps;
        border_size = 1;
        "col.active_border" = "rgba(${base0D}cc) rgba(${base0C}77) 45deg";
        "col.inactive_border" = "rgba(${base02}aa)";
        resize_on_border = true;
        allow_tearing = false;
        layout = "dwindle";
      };

      decoration = {
        inherit rounding;
        inactive_opacity = 1;
        active_opacity = 1;
      };

      animations = {
        enabled = true;
        bezier = ["snap, 0.1, 0.9, 0.2, 1.0"];
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

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };
      master = {new_status = "slave";};
      misc = {disable_hyprland_logo = true;};

      input = {
        repeat_delay = 200;
        repeat_rate = 50;
        follow_mouse = 1;
        sensitivity = 0;
        kb_layout = "us,pt";
        kb_options = "grp:win_space_toggle";
        touchpad.natural_scroll = true;
      };

      gestures = {
        gesture = [
          "3, horizontal,  workspace"
          "4, horizontal,  move"
          "3, vertical,    special, music"
          "4, vertical,    special, messages"
        ];
      };

      "$mainMod" = "SUPER";

      bind = [
        "$mainMod, Q, exec, ${vars.terminal}"
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

        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        "$mainMod, A, workspace, 1"
        "$mainMod, S, workspace, 2"
        "$mainMod, D, workspace, 3"
        "$mainMod, F, workspace, 4"
        "$mainMod, G, workspace, 5"

        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        "$mainMod SHIFT, A, movetoworkspace, 1"
        "$mainMod SHIFT, S, movetoworkspace, 2"
        "$mainMod SHIFT, D, movetoworkspace, 3"
        "$mainMod SHIFT, F, movetoworkspace, 4"
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
        ", switch:on:Lid Switch,  exec, hyprlock & systemctl suspend"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      windowrulev2 = [
        "float,        class:^(spotify)$"
        "center,       class:^(spotify)$"
        "rounding 10,  class:^(spotify)$"

        "bordersize 0, class:vesktop"

        "nofocus, class:^$, title:^$, xwayland:1, floating:1, fullscreen:0, pinned:0"
      ];

      # Regular workspaces are pinned to the primary monitor at runtime
      # by monitor-manager; only the special workspaces need static rules.
      workspace = [
        "special:music,    on-created-empty:spotify"
        "special:messages, on-created-empty:beeper"
      ];
    };
  };
}
