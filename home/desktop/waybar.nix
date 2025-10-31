{
  config,
  pkgs,
  ...
}: {
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        margin-top = 2;
        margin-left = 4;
        margin-right = 4;
        margin-bottom = 1;
        height = 26;

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
          sort-by-number = true;
          persistent-workspaces = {
            "1" = [];
            "2" = [];
            "3" = [];
            "4" = [];
          };
        };

        clock = {
          format = "<span color='#${config.colorScheme.palette.base0D}'></span> {:%H:%M  <span color='#${config.colorScheme.palette.base07}'></span> %b %d}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          on-click = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/date +\"%d-%m-%Y %H:%M\" | ${pkgs.coreutils}/bin/tee >(${pkgs.wl-clipboard}/bin/wl-copy) | ${pkgs.findutils}/bin/xargs -I{} ${pkgs.libnotify}/bin/notify-send \"📋 Date copied\" \"{}\"'";
        };

        memory = {
          states = {
            warning = 70;
            critical = 90;
          };
          format = "<span color='#${config.colorScheme.palette.base0A}'></span> {}%";
          on-click = "alacritty -e btop";
        };

        temperature = {
          critical-threshold = 80;
          format = "<span color='#${config.colorScheme.palette.base0C}'>{icon}</span> {temperatureC}°C";
          format-icons = [
            ""
            ""
            ""
          ];
          on-click = "alacritty -e btop";
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "<span color='#${config.colorScheme.palette.base0B}'>{icon}</span> {capacity}%";
          format-full = "<span color='#${config.colorScheme.palette.base0B}'>{icon}</span> {capacity}%";
          format-charging = "<span color='#${config.colorScheme.palette.base0D}'>󰂄</span> {capacity}%";
          format-plugged = "<span color='#${config.colorScheme.palette.base0D}'></span> {capacity}%";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
        };

        network = {
          format-wifi = "<span color='#${config.colorScheme.palette.base09}'> </span> {signalStrength}%";
          format-ethernet = "<span color='#${config.colorScheme.palette.base09}'></span> {cidr}";
          tooltip-format = "{ifname} via {gwaddr}";
          format-linked = "<span color='#${config.colorScheme.palette.base09}'></span> {ifname} (No IP)";
          format-disconnected = "<span color='#${config.colorScheme.palette.base09}'></span> ⚠ ";
          on-click = "${pkgs.alacritty}/bin/alacritty -e ${pkgs.networkmanager}/bin/nmtui";
        };

        pulseaudio = {
          format = "<span color='#${config.colorScheme.palette.base08}'>{icon}</span> {volume}%";
          format-bluetooth = "{volume}%<span color='#${config.colorScheme.palette.base08}'> {icon} </span>{format_source}";
          format-bluetooth-muted = "<span color='#${config.colorScheme.palette.base03}'></span> {icon} {format_source}";
          format-muted = "<span color='#${config.colorScheme.palette.base03}'></span>";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [
              ""
              ""
              ""
            ];
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
        box-shadow: inset 0 -3px transparent;
        border: none;
        border-radius: 0;
      }

      button:hover {
        background: inherit;
        box-shadow: inset 0 -3px #${base05};
      }

      #clock:hover,
      #battery:hover,
      #memory:hover,
      #temperature:hover,
      #network:hover,
      #pulseaudio:hover,

      #workspaces button {
        padding: 0 5px;
        background-color: transparent;
        color: #${base05};
      }

      #workspaces button:hover {
        background: rgba(0, 0, 0, 0.2);
      }

      #workspaces button.active {
        box-shadow: inset 0 -2px #${base05};
      }

      #workspaces button.urgent {
        background-color: #${base08};
      }

      #clock,
      #battery,
      #memory,
      #temperature,
      #network,
      #pulseaudio {
        padding: 0 10px;
        color: #${base04};
      }

      #window {
        color: #${base04};
      }

      .modules-right,
      .modules-left,
      .modules-center {
        background-color: #${base00};
        border-radius: 7px;
        padding: 1 10px;
      }

      @keyframes blink {
        to {
          color: #${base00};
        }
      }

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
    '';
  };
}
