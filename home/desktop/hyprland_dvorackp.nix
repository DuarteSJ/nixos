{
  config,
  pkgs,
  ...
}: let

  laptopMonitor = config.monitors.laptop;
  externalMonitors = builtins.filter (m: m.enabled) config.monitors.external;

  # Generate workspace rules from monitor configurations
  generateWorkspaces = monitor: 
    map (ws: "${toString ws}, monitor:${monitor.name}") monitor.workspaces;
  
  # Combine all workspace rules
  allWorkspaces = 
    (generateWorkspaces laptopMonitor)
    ++ (builtins.concatMap generateWorkspaces externalMonitors);

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
      monitor = (
        if laptopMonitor.enabled then [
          "${laptopMonitor.name}, ${laptopMonitor.mode}, ${laptopMonitor.position}, ${laptopMonitor.scale}${if laptopMonitor.orientation == "vertical" then ", transform, 1" else ""}"
        ] else [
            "${laptopMonitor.name}, disable"
          ]
      ) ++ (map (m: 
          "${m.name}, ${m.mode}, ${m.position}, ${m.scale}${if m.orientation == "vertical" then ", transform, 1" else ""}"
        ) externalMonitors);

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

      # Keybindings (Dvorak for Programmers)
      # QWERTY -> Dvorak Programmer mapping for physical keys:
      # Q->; W->comma C->J P->R V->K E->. T->Y
      # H->D L->N K->T J->H
      # A->A S->O D->E F->U G->I
      # M->M B->X N->B X->Q
      bind = [
        # Basic bindings
        "$mainMod, semicolon, exec, alacritty"  # Q -> semicolon
        "$mainMod, J, killactive,"              # C -> J
        "$mainMod, P, exec, hyprctl dispatch pin"  # P -> R
        "$mainMod, K, togglefloating,"     # V -> K
        "$mainMod, period, exec, ${rofi-launcher}" # E -> . 
        "$mainMod, R, pseudo,"
        "$mainMod, Y, togglesplit,"             # T -> Y

        # Move focus with mainMod + HJKL (DHTN in Dvorak)
        "$mainMod, D, movefocus, l"  # H -> D
        "$mainMod, N, movefocus, r"  # L -> N
        "$mainMod, T, movefocus, u"  # K -> T
        "$mainMod, H, movefocus, d"  # J -> H

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

        # Alternative bindings for first five workspaces (AOEUI in Dvorak)
        "$mainMod, A, workspace, 1"  # A -> A
        "$mainMod, O, workspace, 2"  # S -> O
        "$mainMod, E, workspace, 3"  # D -> E
        "$mainMod, U, workspace, 4"  # F -> U
        "$mainMod, I, workspace, 5"  # G -> I

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

        # Alternative bindings for first five workspaces (AOEUI in Dvorak)
        "$mainMod SHIFT, A, movetoworkspace, 1"  # A -> A
        "$mainMod SHIFT, O, movetoworkspace, 2"  # S -> O
        "$mainMod SHIFT, E, movetoworkspace, 3"  # D -> E
        "$mainMod SHIFT, U, movetoworkspace, 4"  # F -> U
        "$mainMod SHIFT, I, movetoworkspace, 5"  # G -> I

        # Special workspace "music"
        "$mainMod, W, togglespecialworkspace, music"        # comma -> W
        "$mainMod SHIFT, W, movetoworkspace, special:music" # comma -> W

        # Special workspace "messages"
        "$mainMod, M, togglespecialworkspace, messages"        # M -> M
        "$mainMod SHIFT, M, movetoworkspace, special:messages" # M -> M

        # Script keybindings
        "$mainMod, X, exec, ${toggleWaybar}"             # B -> X
        "$mainMod, B, exec, ${toggleMic}"                # N -> B
        "$mainMod SHIFT, P, exec, ${rofi-powermenu}"
        "$mainMod SHIFT, B, exec, switch-bg"             # N -> B
        "$mainMod, Q, exec, screenshot"                  # X -> Q
        "$mainMod SHIFT, Q, exec, screenrec"             # X -> Q

        # Fullscreen toggle
        "$mainMod, slash, exec, ${toggleAnimations}"

        # Moving windows (DHTN in Dvorak)
        "$mainMod SHIFT, D, swapwindow, l"  # h -> D
        "$mainMod SHIFT, H, swapwindow, d"  # j -> H
        "$mainMod SHIFT, T, swapwindow, u"  # k -> T
        "$mainMod SHIFT, N, swapwindow, r"  # l -> N

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
        # TODO: have a primary monitor instead of just using the first
        targetMonitor = if externalMonitors != [] 
          then builtins.head externalMonitors 
        else laptopMonitor;

        # Get monitor dimensions from mode string (e.g., "1920x1080@60")
        parseMode = mode: let
          resolution = builtins.head (builtins.split "@" mode);
          parts = builtins.split "x" resolution;
        in {
          width = builtins.fromJSON (builtins.elemAt parts 0);
          height = builtins.fromJSON (builtins.elemAt parts 2);
        };

        rawDims = parseMode targetMonitor.mode;

        # Swap dimensions if monitor is vertical
        monitorDims = if targetMonitor.orientation == "vertical" then {
          width = rawDims.height;
          height = rawDims.width;
        } else rawDims;

        # Calculate spotify size (65% of width, 63% of height for example)
        spotifyWidth = toString (monitorDims.width * 65 / 100);
        spotifyHeight = toString (monitorDims.height * 63 / 100);

        # Calculate invis-cava position (full width minus margins, at bottom)
        cavaWidth = toString (monitorDims.width - 30);
        cavaHeight = "181";
        cavaY = toString (monitorDims.height - 181 - 2);
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
        "special:music, on-created-empty:invis-cava & spotify"
        "special:messages, on-created-empty:beeper"
      ] ++ allWorkspaces;
    };
  };
}
