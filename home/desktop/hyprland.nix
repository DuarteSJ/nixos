{
  config,
  pkgs,
  ...
}: let
  externalMonitor = config.monitors.external;
  laptopMonitor = config.monitors.laptop;
  rounding = 0;

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

  toggleAnimations = pkgs.writeShellScript "toggle-animations" ''
    current_value=$(hyprctl getoption animations:enabled | awk '/int:/ {print $2}')
    if [ "$current_value" = "1" ]; then
      hyprctl keyword animations:enabled 0
      dunstify "Animations Disabled" "Window animations have been disabled."
    else
      hyprctl keyword animations:enabled 1
      dunstify "Animations Enabled" "Window animations have been enabled."
    fi
  '';

  disableLaptopMonitor = "hyprctl keyword monitor ${laptopMonitor.name}, disable";

  enableLaptopMonitor = "hyprctl keyword monitor '${laptopMonitor.name},${laptopMonitor.mode},${laptopMonitor.position},${laptopMonitor.scale}${if laptopMonitor.orientation == "vertical" then ",transform,1" else ""}'";

  # if the gaps get higher then 0, set rounding to default value defined above
  increase_gaps = pkgs.writeShellScript "increase-gaps" ''
    current_gaps=$(hyprctl getoption general:gaps_in | awk '{print $3}')
    if [ $current_gaps -eq 0 ]; then
      hyprctl keyword decoration:rounding ${toString rounding}
    fi
    new_gaps=$((current_gaps + 2))
    hyprctl keyword general:gaps_in $new_gaps $new_gaps $new_gaps $new_gaps
    hyprctl keyword general:gaps_out $new_gaps $new_gaps $new_gaps $new_gaps
  '';

  decrease_gaps = pkgs.writeShellScript "decrease-gaps" ''
    current_gaps=$(hyprctl getoption general:gaps_in | awk '{print $3}')
    new_gaps=$((current_gaps - 2))
    if [ $new_gaps -lt 0 ]; then
      new_gaps=0
      hyprctl keyword decoration:rounding 0
    fi
    hyprctl keyword general:gaps_in $new_gaps $new_gaps $new_gaps $new_gaps
    hyprctl keyword general:gaps_out $new_gaps $new_gaps $new_gaps $new_gaps
  '';
in {
  wayland.windowManager.hyprland = {
    enable = true;
    settings = with config.colorScheme.palette; {
      # Monitors
      monitor = [
        "${laptopMonitor.name}, ${laptopMonitor.mode}, ${laptopMonitor.position}, ${laptopMonitor.scale}${if laptopMonitor.orientation == "vertical" then ", transform, 1" else ""}"
        "${externalMonitor.name}, ${externalMonitor.mode}, ${externalMonitor.position}, ${externalMonitor.scale}${if externalMonitor.orientation == "vertical" then ", transform, 1" else ""}"
      ];

      # Autostart
      exec-once = [
        "waybar &"
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
        "col.active_border" = "rgba(${base0D}cc) rgba(${base0C}77) 45deg";
        "col.inactive_border" = "rgba(${base02}aa)";
        resize_on_border = true;
        allow_tearing = false;
        layout = "dwindle";
      };

      # Decoration
      decoration = {
        rounding = rounding;
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
        "$mainMod, Q, exec, alacritty"
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
        "$mainMod, X, exec, screenshot"
        "$mainMod SHIFT, X, exec, screenrec"

        # Fullscreen toggle
        "$mainMod, slash, exec, ${toggleAnimations}"

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

        # Adjust gaps
        "$mainMod, minus, exec, ${increase_gaps}"
        "$mainMod, equal, exec, ${decrease_gaps}"
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
      windowrulev2 = let
        # Get monitor dimensions from mode string (e.g., "1920x1080@60")
        parseMode = mode: let
          resolution = builtins.head (builtins.split "@" mode);
          parts = builtins.split "x" resolution;
        in {
          width = builtins.fromJSON (builtins.elemAt parts 0);
          height = builtins.fromJSON (builtins.elemAt parts 2);
        };

        rawDims = parseMode externalMonitor.mode;

        # Swap dimensions if monitor is vertical
        externalDims = if externalMonitor.orientation == "vertical" then {
          width = rawDims.height;
          height = rawDims.width;
        } else rawDims;

        # Calculate spotify size (65% of width, 63% of height for example)
        spotifyWidth = toString (externalDims.width * 65 / 100);
        spotifyHeight = toString (externalDims.height * 63 / 100);

        # Calculate invis-cava position (full width minus margins, at bottom)
        cavaWidth = toString (externalDims.width - 30);
        cavaHeight = "181";
        cavaY = toString (externalDims.height - 181 - 2);
      in [
        # Spotify
        "float, class:^(spotify)$"
        "size ${spotifyWidth} ${spotifyHeight}, class:^(spotify)$"
        "center, class:^(spotify)$"
        "rounding 10, class:^(spotify)$"

        # Vesktop
        "bordersize 0, class:vesktop"

        # invis-cava
        "float, class:^(invis-cava)$"
        "size ${cavaWidth} ${cavaHeight}, class:^(invis-cava)$"
        "move 0 ${cavaY}, class:^(invis-cava)$"
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
