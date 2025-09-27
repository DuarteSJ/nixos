{ config, pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = with config.colorScheme.palette; {
      # Monitors
      monitor = [
        "eDP-1, disable"
        "HDMI-A-1, 1920x1080@60, 1920x-850x, 1"
      ];

      # Programs
      "$terminal" = "alacritty";
      "$menu" = "~/.local/bin/rofi-launcher";

      # Autostart
      exec-once = [
        "/home/duartesj/scripts/autostart.sh"
      ];

      # Environment variables
      env = [
        "HYPRCURSOR_THEME,Nordzy-cursors"
        "HYPRCURSOR_SIZE,26"
      ];

      # General settings
      general = {
        gaps_in = 4;
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
        "$mainMod, E, exec, hyprctl dispatch pin"
        "$mainMod, V, togglefloating,"
        "$mainMod, P, exec, $menu"
        "$mainMod, R, pseudo," # dwindle
        "$mainMod, T, togglesplit," # dwindle

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

        # Special workspace (scratchpad)
        "$mainMod, S, togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"

        # Scroll through existing workspaces with mainMod + scroll
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"

        # Script keybindings
        "$mainMod, Tab, exec, /home/duartesj/scripts/alt_tab.sh"
        "$mainMod, B, exec, bash -c \"pgrep waybar && pkill waybar || waybar &\""
        "$mainMod SHIFT, D, exec, /home/duartesj/scripts/pomodoro.sh"
        "$mainMod SHIFT, M, exec, pactl set-source-mute @DEFAULT_SOURCE@ toggle"
        "$mainMod SHIFT, P, exec, ~/.local/bin/rofi-powermenu"
        "$mainMod SHIFT, N, exec, /home/duartesj/scripts/alter_background.sh"
        "$mainMod SHIFT, X, exec, sh -c 'grim -g \"$(slurp)\" - | tee ~/Pictures/screenshots/screenshot_$(date +%d_%m_%Y_%H:%M:%S).png | wl-copy'"
        "$mainMod SHIFT, R, exec, /home/duartesj/scripts/keyviz.sh"
        "$mainMod, M, exec, /home/duartesj/scripts/music.sh"

        # Fullscreen toggle
        "$mainMod, F, exec, bash -c 'topgap=$(hyprctl getoption general:gaps_in | awk \"{print \\$3}\"); if [ \"$topgap\" -ne 0 ]; then hyprctl --batch \"keyword general:gaps_in 0 0 0 0 ; keyword general:gaps_out 0 0 0 0 ; keyword general:border_size 0 ; keyword decoration:rounding 0 ; keyword decoration:drop_shadow false; keyword animations:enabled 0\"; pkill waybar; else hyprctl reload; if ! pgrep waybar >/dev/null; then waybar & fi; fi'"

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
        ",XF86AudioMute, exec, wpctl set-sink-mute @DEFAULT_SINK@ toggle"
        ",XF86AudioMicMute, exec, wpctl set-source-mute @DEFAULT_SOURCE@ toggle"
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
        "float, class:^(Spotify)$"
        "size 1255 686, class:^(Spotify)$"
        "center, class:^(Spotify)$"

        # Vesktop
        "bordersize 0, class:vesktop"

        # Fix some dragging issues with XWayland
        "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
      ];
    };
  };
}
