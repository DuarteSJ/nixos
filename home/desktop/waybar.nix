{ config, pkgs, ... }:
{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        margin-top = 2;
        margin-left = 4;
        margin-right = 4;
        margin-bottom = 1;
        height = 25;
        
        modules-left = [
          "hyprland/workspaces"
          "hyprland/window"
        ];
        
        modules-center = [
          "clock"
        ];
        
        modules-right = [
          "pulseaudio"
          "network"
          "memory"
          "temperature"
          "battery"
        ];

        "hyprland/window" = {
          format = "  {}";
          max-length = 35;
          rewrite = {
            "" = "";
          };
          separate-outputs = true;
        };

        "hyprland/workspaces" = {
          format = "{icon}";
          on-click = "activate";
          format-icons = {
            active = "";
          };
          sort-by-number = true;
        };

        clock = {
          format = "{:%a %d %b %H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          on-click = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/date +\"%d-%m-%Y %H:%M\" | ${pkgs.coreutils}/bin/tee >(${pkgs.wl-clipboard}/bin/wl-copy) | ${pkgs.findutils}/bin/xargs -I{} ${pkgs.libnotify}/bin/notify-send \"📋 Date copied\" \"{}\"'";
        };

        memory = {
          states = {
            warning = 70;
            critical = 90;
          };
          format = " {}%";
          on-click = "alacritty -e btop";
        };

        temperature = {
          critical-threshold = 80;
          format = "{icon} {temperatureC}°C";
          format-icons = ["" "" ""];
          on-click = "alacritty -e btop";
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-full = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-plugged = " {capacity}%";
          format-icons = ["" "" "" "" ""];
          on-click = "bash -c '~/scripts/battery_times.sh'";
        };

        network = {
          format-wifi = " {signalStrength}%";
          format-ethernet = "{cidr}";
          tooltip-format = "{ifname} via {gwaddr}";
          format-linked = "{ifname} (No IP)";
          format-disconnected = " ⚠ ";
          on-click = "bash -c 'ip -4 addr show $(ip route | grep default | awk \"{print \\$5}\") | grep -oP \"(?<=inet\\s)\\d+(\\.\\d+){3}\" | head -n1 | tee >(wl-copy) | xargs -I{} notify-send \"📡 IP copied\" \"{}\"'";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-bluetooth = "{volume}% {icon} {format_source}";
          format-bluetooth-muted = " {icon} {format_source}";
          format-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = ["" "" ""];
          };
          on-click = "pavucontrol";
        };
      };
    };

    style = with config.colorScheme.palette; ''
      * {
        font-family: "JetBrainsMono Nerd Font", Roboto, Helvetica, Arial, sans-serif;
        font-size: 16px;
      }

      window#waybar {
        background-color: rgba(0, 0, 0, 0);
        border-radius: 13px;
        transition-property: background-color;
        transition-duration: .5s;
      }

      button {
        /* Use box-shadow instead of border so the text isn't offset */
        box-shadow: inset 0 -3px transparent;
        /* Avoid rounded borders under each button name */
        border: none;
        border-radius: 0;
      }

      /* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
      button:hover {
        background: inherit;
        box-shadow: inset 0 -3px #${base05};
      }

      /* you can set a style on hover for any module like this */
      #clock:hover,
      #battery:hover,
      #cpu:hover,
      #memory:hover,
      #temperature:hover,
      #network:hover,
      #pulseaudio:hover {
        background-color: #${base02};
      }

      #workspaces button {
        padding: 0 5px;
        background-color: transparent;
        color: #${base05};
      }

      #workspaces button:hover {
        background: rgba(0, 0, 0, 0.2);
      }

      #workspaces button.focused {
        background-color: #${base0E};
        box-shadow: inset 0 -3px #${base05};
      }

      #workspaces button.urgent {
        background-color: #${base08};
      }

      #mode {
        background-color: #${base03};
        box-shadow: inset 0 -3px #${base05};
      }

      #clock,
      #battery,
      #cpu,
      #memory,
      #temperature,
      #network,
      #pulseaudio {
        padding: 0 10px;
      }

      #memory {
        color: #${base0A};
      }

      #pulseaudio {
        color: #${base08};
      }

      #network {
        color: #${base09};
      }

      #temperature {
        color: #${base0C};
      }

      #battery {
        color: #${base0B};
      }

      #clock {
        color: #${base05};
      }

      #window {
        color: #${base04};
      }

      .modules-right,
      .modules-left,
      .modules-center {
        background-color: #${base00};
        border-radius: 15px;
      }

      .modules-right {
        padding: 0 10px;
      }

      .modules-left {
        padding: 0 20px;
      }

      .modules-center {
        padding: 0 10px;
      }

      #battery.charging,
      #battery.plugged {
        color: #${base0D};
      }

      @keyframes blink {
        to {
          color: #${base00};
        }
      }

      /* Using steps() instead of linear as a timing function to limit cpu usage */
      #battery.critical:not(.charging) {
        background-color: #${base08};
        color: #${base05};
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: steps(12);
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      #memory.critical {
        background-color: #${base08};
        color: #${base05};
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: steps(12);
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      label:focus {
        background-color: #${base00};
      }

      #pulseaudio.muted {
        color: #${base03};
      }
    '';
  };
}
