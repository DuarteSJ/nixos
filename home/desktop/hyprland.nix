{ config, pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = with config.colorScheme.palette; {
      # Monitors
      monitor = [
        # "eDP-1, preferred, auto, 1"
        "eDP-1, disabled"
        "HDMI-A-1, 1920x1080@60, 1920x-850x, 1"
      ];

      # Programs
      "$terminal" = "alacritty";
      "$menu" = "~/.local/bin/rofi-launcher";

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
        border_size = 2;
        # Using nix-colors for borders
        "col.active_border" = "rgba(${base0D}ff) rgba(${base0C}ff) 45deg";
        "col.inactive_border" = "rgba(${base02}aa)";
        resize_on_border = true;
        allow_tearing = false;
        layout = "dwindle";
      };

      # Decoration
      decoration = {
        rounding = 9;
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
          "easeOutQuint,0.23,1,0.32,1"
          "easeInOutCubic,0.65,0.05,0.36,1"
          "linear,0,0,1,1"
          "almostLinear,0.5,0.5,0.75,1.0"
          "quick,0.15,0,0.1,1"
        ];

        animation = [
          "global, 1, 10, default"
          "border, 1, 5.39, easeOutQuint"
          "windows, 1, 4.79, easeOutQuint"
          "windowsIn, 1, 3.49, easeOutQuint, popin 17%"
          "windowsOut, 1, 3.49, linear, popin 17%"
          "fadeIn, 1, 1.73, almostLinear"
          "fadeOut, 1, 1.46, almostLinear"
          "fade, 1, 3.03, quick"
          "layers, 1, 3.81, easeOutQuint"
          "layersIn, 1, 4, easeOutQuint, fade"
          "layersOut, 1, 1.5, linear, fade"
          "fadeLayersIn, 1, 1.79, almostLinear"
          "fadeLayersOut, 1, 1.39, almostLinear"
          "workspaces, 1, 3.21, easeInOutCubic, slide"
          "specialWorkspace, 1, 5, easeInOutCubic, slidevert"
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
        "$mainMod, E, exec, $menu"
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

        # Alternative bindings for first four workspaces
        "$mainMod, A, workspace, 1"
        "$mainMod, S, workspace, 2"
        "$mainMod, D, workspace, 3"
        "$mainMod, F, workspace, 4"

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

        # Alternative bindings for first four workspaces
        "$mainMod SHIFT, A, movetoworkspace, 1"
        "$mainMod SHIFT, S, movetoworkspace, 2"
        "$mainMod SHIFT, D, movetoworkspace, 3"
        "$mainMod SHIFT, F, movetoworkspace, 4"

        # Special workspace (scratchpad)
        "$mainMod, M, togglespecialworkspace, magic"
        "$mainMod SHIFT, M, movetoworkspace, special:magic"

        # Scroll through existing workspaces with mainMod + scroll
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"

        # Script keybindings
        "$mainMod, B, exec, bash -c \"pgrep waybar && pkill waybar || waybar &\""
        "$mainMod SHIFT, M, exec, sh -c 'wpctl set-mute @DEFAULT_SOURCE@ toggle; dunstify \"Mic Status\" \"$(wpctl get-volume @DEFAULT_SOURCE@ | grep -q \"MUTED\" && echo Microphone is now muted || echo Microphone is now unmuted)\"'"
        "$mainMod SHIFT, P, exec, ~/.local/bin/rofi-powermenu"
        "$mainMod SHIFT, N, exec, switch-bg"
        "$mainMod SHIFT, X, exec, screenshot"

        # Fullscreen toggle
        "$mainMod, slash, exec, bash -c 'topgap=$(hyprctl getoption general:gaps_in | awk \"{print \\$3}\"); if [ \"$topgap\" -ne 0 ]; then hyprctl --batch \"keyword general:gaps_in 0 0 0 0 ; keyword general:gaps_out 0 0 0 0 ; keyword general:border_size 1 ; keyword decoration:rounding 0 ; keyword decoration:drop_shadow false; keyword animations:enabled 0\"; pkill waybar; else hyprctl reload; if ! pgrep waybar >/dev/null; then waybar & fi; fi'"

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
	",XF86AudioMicMute, exec, sh -c 'wpctl set-mute @DEFAULT_SOURCE@ toggle; dunstify \"Mic Status\" \"$(wpctl get-volume @DEFAULT_SOURCE@ | grep -q \"MUTED\" && echo Microphone is now muted || echo Microphone is now unmuted)\"'"
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_SINK@ toggle"
        ",XF86MonBrightnessUp, exec, brightnessctl s 2%+"
        ",XF86MonBrightnessDown, exec, brightnessctl s 2%-"
      ];

      # Locked bindings (work even when locked)
      bindl = [
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
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
      ];
    };
  };
}
