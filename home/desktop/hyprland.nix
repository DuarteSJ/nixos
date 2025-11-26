{
  config,
  pkgs,
  ...
}: let
  externalMonitor = config.monitors.external;
  laptopMonitor = config.monitors.laptop;

  # Scripts
  rofi-launcher = pkgs.writeShellScript "rofi-launcher" ''
    #!/run/current-system/sw/bin/bash
    rofi -show drun
  '';

  rofi-powermenu = pkgs.writeShellScript "rofi-powermenu" ''
    #!/run/current-system/sw/bin/bash

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

  toggleFullscreen = pkgs.writeShellScript "toggle-fullscreen" ''
  # Original settings from config
  GAPS_IN="${toString config.wayland.windowManager.hyprland.settings.general.gaps_in}"
  GAPS_OUT="${toString config.wayland.windowManager.hyprland.settings.general.gaps_out}"
  BORDER_SIZE="${toString config.wayland.windowManager.hyprland.settings.general.border_size}"
  ROUNDING="${toString config.wayland.windowManager.hyprland.settings.decoration.rounding}"
  DROP_SHADOW="${toString config.wayland.windowManager.hyprland.settings.decoration.shadow.enabled}"
  ANIMATIONS="${toString config.wayland.windowManager.hyprland.settings.animations.enabled}"

  topgap=$(hyprctl getoption general:gaps_in | awk '{print $3}')

  if [ "$topgap" -ne 0 ]; then
    # Enter fullscreen mode
    hyprctl --batch "\
      keyword general:gaps_in 0 0 0 0; \
      keyword general:gaps_out 0 0 0 0; \
      keyword general:border_size 1; \
      keyword decoration:rounding 0; \
      keyword decoration:drop_shadow false; \
      keyword animations:enabled 0"
  else
    # Exit fullscreen mode: restore original settings
    hyprctl --batch "\
      keyword general:gaps_in $GAPS_IN; \
      keyword general:gaps_out $GAPS_OUT; \
      keyword general:border_size $BORDER_SIZE; \
      keyword decoration:rounding $ROUNDING; \
      keyword decoration:drop_shadow $DROP_SHADOW; \
      keyword animations:enabled $ANIMATIONS"

    # Restart waybar if it's not running
    if ! pgrep waybar > /dev/null; then
      waybar &
    fi
  fi
  '';

  disableLaptopMonitor = "hyprctl keyword monitor ${laptopMonitor.name}, disable";

  enableLaptopMonitor = "hyprctl keyword monitor '${laptopMonitor.name},${laptopMonitor.mode},${laptopMonitor.position},${laptopMonitor.scale}'";
in {
  wayland.windowManager.hyprland = {
    enable = true;
    settings = with config.colorScheme.palette; {
      # Variables
      "$terminal" = "alacritty";

      # Monitors
      monitor = [
        "${laptopMonitor.name}, ${laptopMonitor.mode}, ${laptopMonitor.position}, ${laptopMonitor.scale}"
        # "$laptopMonitor, disabled"
        "${externalMonitor.name}, ${externalMonitor.mode}, ${externalMonitor.position}, ${externalMonitor.scale}"
      ];

      # Autostart
      exec-once = [
        "waybar &"
        "swww-daemon &"
      ];

      # Environment variables
      env = [
        "HYPRCURSOR_THEME,Nordzy-cursors"
        "HYPRCURSOR_SIZE,26"
      ];

      # General settings
      general = {
        gaps_in = 2;
        gaps_out = 4;
        border_size = 1;
        # Using nix-colors for borders
        "col.active_border" = "rgba(${base0D}ff) rgba(${base0C}ff) 45deg";
        "col.inactive_border" = "rgba(${base02}aa)";
        resize_on_border = true;
        allow_tearing = false;
        layout = "dwindle";
      };

      # Decoration
      decoration = {
        rounding = 7;
        inactive_opacity = 1;
        active_opacity = 1;

        shadow = {
          enabled = false;
          range = 96;
          render_power = 3;
          color = "rgba(${base00}ff)";
        };

        blur = {
          enabled = false;
          size = 3;
          passes = 1;
          vibrancy = 0.1696;
        };
      };

      # Animations
      animations = {
        enabled = true;
        bezier = [
          "wind, 0.05, 0.9, 0.1, 1.05"
          "winIn, 0.1, 1.1, 0.1, 1.1"
          "winOut, 0.3, -0.3, 0, 1"
        ];
        animation = [
          "windowsIn, 1, 3, wind, slide"
          "windowsOut, 1, 3, wind, slide"
          "windowsMove, 1, 3, wind, slide"
          "border, 1, 6, wind"
          "fade, 1, 3, wind"
          "workspaces, 1, 4, wind"
          "specialWorkspace, 1, 4, wind, slidefadevert 70%"
        ];
      };

      # Dwindle layout
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      # Master layout
      master = {
        new_status = "slave";
      };

      # Misc
      misc = {
        disable_hyprland_logo = true;
      };

      # Input
      input = {
        repeat_delay = 200;
        repeat_rate = 50;
        follow_mouse = 1;
        sensitivity = 0;
        kb_layout = "us,pt";
        kb_options = "grp:win_space_toggle";

        touchpad = {
          natural_scroll = true;
        };
      };

      # Gestures
      gestures = {
        workspace_swipe_forever = true;
      };

      # Main modifier
      "$mainMod" = "SUPER";

      # Keybindings
      bind = [
        # Basic bindings
        "$mainMod, Q, exec, $terminal"
        "$mainMod, C, killactive,"
        "$mainMod, P, exec, hyprctl dispatch pin"
        "$mainMod, V, togglefloating,"
        "$mainMod, E, exec, ${rofi-launcher}"
        "$mainMod, R, pseudo,"
        "$mainMod, T, togglesplit,"

        # Move focus with mainMod + HJKL
        "$mainMod, H, movefocus, l"
        "$mainMod, L, movefocus, r"
        "$mainMod, K, movefocus, u"
        "$mainMod, J, movefocus, d"

        # Switch workspaces with mainMod + [0-9]
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

        # Alternative bindings for first five workspaces
        "$mainMod, A, workspace, 1"
        "$mainMod, S, workspace, 2"
        "$mainMod, D, workspace, 3"
        "$mainMod, F, workspace, 4"
        "$mainMod, G, workspace, 5"

        # Move active window to a workspace with mainMod + SHIFT + [0-9]
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

        # Alternative bindings for first five workspaces
        "$mainMod SHIFT, A, movetoworkspace, 1"
        "$mainMod SHIFT, S, movetoworkspace, 2"
        "$mainMod SHIFT, D, movetoworkspace, 3"
        "$mainMod SHIFT, F, movetoworkspace, 4"
        "$mainMod SHIFT, G, movetoworkspace, 5"

        # Special workspace (scratchpad)
        "$mainMod, M, togglespecialworkspace, magic"
        "$mainMod SHIFT, M, movetoworkspace, special:magic"

        # Scroll through existing workspaces with mainMod + scroll
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"

        # Script keybindings
        "$mainMod, B, exec, ${toggleWaybar}"
        "$mainMod, N, exec, ${toggleMic}"
        "$mainMod SHIFT, P, exec, ${rofi-powermenu}"
        "$mainMod SHIFT, N, exec, switch-bg"
        "$mainMod SHIFT, X, exec, screenshot"

        # Fullscreen toggle
        "$mainMod, slash, exec, ${toggleFullscreen}"

        # Moving windows
        "$mainMod SHIFT, h, swapwindow, l"
        "$mainMod SHIFT, j, swapwindow, d"
        "$mainMod SHIFT, k, swapwindow, u"
        "$mainMod SHIFT, l, swapwindow, r"

        # Resize windows
        "$mainMod, Left, resizeactive, -65 0"
        "$mainMod, Down, resizeactive, 0 65"
        "$mainMod, Up, resizeactive, 0 -65"
        "$mainMod, Right, resizeactive, 65 0"
      ];

      # Repeat bindings for volume and brightness
      bindel = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_SINK@ 0.05+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_SINK@ 0.05-"
        ",XF86AudioMicMute, exec, ${toggleMic}"
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_SINK@ toggle"
        ",XF86MonBrightnessUp, exec, brightnessctl s 4%+"
        ",XF86MonBrightnessDown, exec, brightnessctl s 4%-"
      ];

      # Locked bindings (work even when locked)
      bindl = [
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
        ", switch:on:Lid Switch, exec, ${disableLaptopMonitor}"
        ", switch:off:Lid Switch, exec, ${enableLaptopMonitor}"
      ];

      # Mouse bindings
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      # Window rules
      windowrulev2 = [
        # Spotify
        "float, class:^(spotify)$"
        "size 1255 686, class:^(spotify)$"
        "center, class:^(spotify)$"

        # Vesktop
        "bordersize 0, class:vesktop"

        # invis-cava
        "float, class:^(invis-cava)$"
        "size 1954 181, class:^(invis-cava)$"
        "move -15 902, class:^(invis-cava)$"
        "noborder, class:^(invis-cava)$"
        "noanim, class:^(invis-cava)$"

        # Fix some dragging issues with XWayland
        "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
      ];

      # Workspace rules
      workspace = [
        "special:magic, on-created-empty:invis-cava & spotify"

        "1, monitor:${externalMonitor.name}, default:true"
        "2, monitor:${externalMonitor.name}"
        "3, monitor:${externalMonitor.name}"
        "4, monitor:${externalMonitor.name}"
        "5, monitor:${laptopMonitor.name}"
        "6, monitor:${externalMonitor.name}"
        "7, monitor:${externalMonitor.name}"
        "8, monitor:${externalMonitor.name}"
        "9, monitor:${externalMonitor.name}"
        "10, monitor:${externalMonitor.name}"
      ];
    };
  };
}
