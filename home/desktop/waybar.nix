{
  config,
  pkgs,
  lib,
  ...
}: let
  colors = config.colorScheme.palette;
  inherit (config) vars;

  # Show the configured workspaces as persistent buttons on every
  # output.  The manager pins them to the primary monitor at runtime;
  # on any other bar they show as empty and click-switch as usual.
  persistentWorkspaces = {
    "*" = config.monitors.workspaces;
  };

  # Icon collections
  icons = {
    window = "|";
    clock = "";
    calendar = "";
    memory = "";
    temperature = {
      normal = "";
      warm = "";
      hot = "";
    };
    battery = {
      levels = ["󰁺" "󰁼" "󰁾" "󰂀" "󰁹"];
      charging = "󰂄";
      plugged = "";
    };
    network = {
      wifi = "";
      ethernet = "󰈁";
      linked = "";
      disconnected = "";
    };
    audio = {
      muted = "";
      headphone = "";
      hands-free = "";
      headset = "";
      phone = "";
      portable = "Portable";
      car = "";
      levels = ["" "" ""];
    };
    recording = {
      active = "■";
      inactive = "●";
    };
  };

  # Color keys for module icons
  moduleColors = {
    clock = "base0D";
    memory = "base0A";
    temperature = "base0C";
    battery = "base0B";
    batteryCharging = "base0D";
    network = "base09";
    audio = "base08";
    muted = "base03";
    recording = "base08";
    recordingInactive = "base03";
  };

  # State thresholds
  thresholds = {
    memory = {
      warning = 70;
      critical = 90;
    };
    battery = {
      warning = 30;
      critical = 15;
    };
    temperature = {
      critical = 80;
    };
  };

  # Helper: wrap icon in a colored span
  coloredIcon = icon: colorKey: "<span color='#${colors.${colorKey}}'>${icon}</span>";

  # Helper: build a module with a leading colored icon
  mkModuleWithIcon = icon: colorKey: formatStr: extra:
    {
      format = "${coloredIcon icon colorKey} ${formatStr}";
    }
    // extra;

  # Build path for terminal commands
  mkTermCmd = bin: "${pkgs.alacritty}/bin/alacritty -e ${bin}";
in {
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        # Bar layout
        margin-top = 2;
        margin-left = vars.gaps;
        margin-right = vars.gaps;
        margin-bottom = 0;
        height = 26;

        modules-left = ["hyprland/workspaces" "hyprland/window" "custom/screenrec"];
        modules-center = ["clock"];
        modules-right = ["pulseaudio" "network" "memory" "temperature" "battery"];

        # Window title
        "hyprland/window" = {
          format = "${icons.window}  {}";
          max-length = 35;
          separate-outputs = true;
        };

        # Workspaces
        "hyprland/workspaces" = {
          format = "{icon}";
          on-click = "activate";
          sort-by-number = true;
          persistent-workspaces = persistentWorkspaces;
        };

        # Clock with date copy functionality
        clock =
          mkModuleWithIcon icons.clock moduleColors.clock
          "{:%H:%M  ${coloredIcon icons.calendar "base07"} %b %d}"
          {
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            on-click = lib.concatStringsSep " | " [
              "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/date +\"%d-%m-%Y · %H:%M\""
              "${pkgs.coreutils}/bin/tee >(${pkgs.wl-clipboard}/bin/wl-copy)"
              "${pkgs.findutils}/bin/xargs -I{} ${pkgs.libnotify}/bin/notify-send \"📋 Date copied\" \"{}\"'"
            ];
          };

        # System monitoring modules
        memory = mkModuleWithIcon icons.memory moduleColors.memory "{}%" {
          states = thresholds.memory;
          on-click = mkTermCmd "btop";
        };

        temperature = mkModuleWithIcon "{icon}" moduleColors.temperature "{temperatureC}°C" {
          critical-threshold = thresholds.temperature.critical;
          format-icons = with icons.temperature; [normal warm hot];
          on-click = mkTermCmd "btop";
          hwmon-path = "/sys/class/hwmon/hwmon6/temp1_input";
        };

        battery = {
          states = thresholds.battery;
          format = "${coloredIcon "{icon}" moduleColors.battery} {capacity}%";
          format-full = "${coloredIcon "{icon}" moduleColors.battery} {capacity}%";
          format-charging = "${coloredIcon icons.battery.charging moduleColors.batteryCharging} {capacity}%";
          format-plugged = "${coloredIcon icons.battery.plugged moduleColors.batteryCharging} {capacity}%";
          format-icons = icons.battery.levels;
        };

        # Network with nmtui integration
        network = with icons.network; {
          format-wifi = "${coloredIcon wifi moduleColors.network} {signalStrength}%";
          format-ethernet = "${coloredIcon ethernet moduleColors.network} {cidr}";
          tooltip-format = "{ifname} via {gwaddr}";
          format-linked = "${coloredIcon linked moduleColors.network} {ifname} (No IP)";
          format-disconnected = "${coloredIcon disconnected moduleColors.network} ⚠ ";
          on-click = mkTermCmd "${pkgs.networkmanager}/bin/nmtui";
        };

        # Audio with pavucontrol
        pulseaudio = mkModuleWithIcon "{icon}" moduleColors.audio "{volume}%" {
          format-bluetooth = "{volume}% ${coloredIcon "{icon}" moduleColors.audio} {format_source}";
          format-bluetooth-muted = "${coloredIcon icons.audio.muted moduleColors.muted} {icon} {format_source}";
          format-muted = coloredIcon icons.audio.muted moduleColors.muted;
          format-icons = with icons.audio; {
            inherit headphone hands-free headset phone portable car;
            default = levels;
          };
          on-click = "pavucontrol";
        };

        # Screen recording indicator (only shows when recording)
        "custom/screenrec" = {
          exec = ''
            if [ -f "/tmp/screenrec-recording" ]; then
              echo '{"text": "${icons.recording.active} REC", "class": "recording"}'
            else
              echo '{"text": "", "class": "hidden"}'
            fi
          '';
          return-type = "json";
          interval = 1;
          signal = 8;
          on-click = "screenrec";
          tooltip-format = "Click to stop recording";
          format = "{}";
        };
      };
    };

    style = ''
      * {
        font-family: "${vars.font.name}", Roboto, Helvetica, Arial, sans-serif;
        font-size: 16px;
      }

      window#waybar {
        background-color: rgba(0, 0, 0, 0);
        border-radius: 13px;
        transition-property: background-color;
        transition-duration: .5s;
      }

      window#waybar.empty #window {
        opacity: 0;
        padding: 0;
        margin: 0;
      }

      button {
        box-shadow: inset 0 -3px transparent;
        border: none;
        border-radius: 0;
      }

      button:hover {
        background: inherit;
        box-shadow: inset 0 -3px #${colors.base05};
      }

      /* Workspace buttons */
      #workspaces button {
        padding: 0 5px;
        background-color: transparent;
        color: #${colors.base05};
      }

      #workspaces button:hover {
        background: rgba(0, 0, 0, 0.2);
      }

      #workspaces button.active {
        box-shadow: inset 0 -2px #${colors.base05};
      }

      #workspaces button.urgent {
        background-color: #${colors.base08};
      }

      /* Module styling */
      #clock,
      #battery,
      #memory,
      #temperature,
      #network,
      #pulseaudio,
      #window,
      #custom-screenrec {
        padding: 0 10px;
        color: #${colors.base04};
      }

      /* Module group backgrounds */
      .modules-right,
      .modules-left,
      .modules-center {
        background-color: #${colors.base00};
        border-radius: ${toString vars.rounding};
        padding: 1 10px;
      }

      /* Critical state animation */
      @keyframes blink {
        to {
          color: #${colors.base00};
        }
      }

      #battery.critical:not(.charging),
      #memory.critical {
        background-color: #${colors.base08};
        color: #${colors.base05};
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: steps(12);
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      /* Screen recording indicator */
      #custom-screenrec {
        padding: 0 10px;
        margin-left: 10px;
      }

      #custom-screenrec.recording {
        background-color: #${colors.base08};
        color: #${colors.base00};
        border-radius: 4px;
        font-weight: bold;
      }

      #custom-screenrec.hidden {
        padding: 0;
        margin: 0;
      }

      label:focus {
        background-color: #${colors.base00};
      }
    '';
  };
}
