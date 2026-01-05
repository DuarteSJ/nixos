{
  config,
  pkgs,
  lib,
  ...
}: let
  colors = config.colorscheme.palette;
  mainMonitor = config.monitors.external.name;
  auxMonitor = config.monitors.laptop.name;

  # Icon collections
  icons = {
    window = "";
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

  # Color references for module icons
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

  # Helper to create colored icon span
  coloredIcon = icon: color: "<span color='#${colors.${color}}'>${icon}</span>";

  # Helper to build module with icon
  mkModuleWithIcon = icon: color: formatStr: extra:
    {
      format = "${coloredIcon icon color} ${formatStr}";
    }
    // extra;

  # Helper to build clickable terminal module
  mkTerminalModule = module: icon: color: formatStr: app:
    mkModuleWithIcon icon color formatStr {
      on-click = "${app}";
    };

  # Build path for terminal commands
  mkTermCmd = bin: "${pkgs.alacritty}/bin/alacritty -e ${bin}";

  # Common module groups for CSS
  allModules = ["clock" "battery" "memory" "temperature" "network" "pulseaudio" "window" "custom-screenrec"];
  interactiveModules = ["clock" "battery" "memory" "temperature" "network" "pulseaudio" "custom-screenrec"];
in {
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        # Bar layout
        margin-top = 2;
        margin-left = 4;
        margin-right = 4;
        margin-bottom = 1;
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
          persistent-workspaces = {
            "${mainMonitor}" = [1 2 3 4];
            "${auxMonitor}" = [5];
          };
        };

        # Clock with date copy functionality
        clock = mkModuleWithIcon icons.clock moduleColors.clock 
          "{:%H:%M  ${coloredIcon icons.calendar "base07"} %b %d}" {
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          on-click = lib.concatStringsSep " | " [
            "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/date +\"%d-%m-%Y · %H:%M\""
            "${pkgs.coreutils}/bin/tee >(${pkgs.wl-clipboard}/bin/wl-copy)"
            "${pkgs.findutils}/bin/xargs -I{} ${pkgs.libnotify}/bin/notify-send \"📋 Date copied\" \"{}\"'"
          ];
        };

        # System monitoring modules
        memory = mkTerminalModule
          "memory"
          icons.memory
          moduleColors.memory
          "{}%"
          (mkTermCmd "btop") // {states = thresholds.memory;};

        temperature = mkTerminalModule
          "temperature"
          "{icon}"
          moduleColors.temperature
          "{temperatureC}°C"
          (mkTermCmd "btop") // {
          critical-threshold = thresholds.temperature.critical;
          format-icons = with icons.temperature; [normal warm hot];
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

    style = with colors;
      let
        # Generate CSS selectors from list
        mkSelectors = list: builtins.concatStringsSep ",\n" (builtins.map (m: "#${m}") list);
        mkHoverSelectors = list: builtins.concatStringsSep ",\n" (builtins.map (m: "#${m}:hover") list);
      in ''
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
          box-shadow: inset 0 -3px #${base05};
        }

        /* Workspace buttons */
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

        /* Module styling */
        ${mkSelectors allModules} {
          padding: 0 10px;
          color: #${base04};
        }

        /* Module group backgrounds */
        .modules-right,
        .modules-left,
        .modules-center {
          background-color: #${base00};
          border-radius: 4px;
          padding: 1 10px;
        }

        /* Critical state animation */
        @keyframes blink {
          to {
            color: #${base00};
          }
        }

        #battery.critical:not(.charging),
        #memory.critical {
          background-color: #${base08};
          color: #${base05};
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
          background-color: #${base08};
          color: #${base00};
          border-radius: 4px;
          font-weight: bold;
        }

        #custom-screenrec.hidden {
          padding: 0;
          margin: 0;
        }

        label:focus {
          background-color: #${base00};
        }
      '';
  };
}
