# Shell scripts invoked from keybinds.
# writeShellApplication injects a deterministic PATH (runtimeInputs), enables
# strict mode (set -euo pipefail) and runs shellcheck at build time.  Call
# sites reference these via `lib.getExe` (they're packages, not bare files).
{pkgs}: {
  rofi-launcher = pkgs.writeShellApplication {
    name = "rofi-launcher";
    runtimeInputs = [pkgs.rofi];
    text = ''
      rofi -show drun
    '';
  };

  rofi-powermenu = pkgs.writeShellApplication {
    name = "rofi-powermenu";
    runtimeInputs = [pkgs.rofi pkgs.systemd pkgs.hyprlock pkgs.hyprland];
    text = ''
      shutdown="⏻ shutdown"
      reboot=" reboot"
      lock=" lock"
      logout=" logout"
      suspend=" suspend"

      options="$lock\n$suspend\n$shutdown\n$reboot\n$logout"

      chosen=$(echo -e "$options" | rofi -dmenu -p "Power Menu") || exit 0

      case "$chosen" in
          "$shutdown") systemctl poweroff ;;
          "$reboot")   systemctl reboot ;;
          "$lock")     hyprlock ;;
          # Hyprland 0.55.x evaluates `hyprctl dispatch <arg>` as Lua
          # (hl.dispatch(arg)), so it needs an hl.dsp.* descriptor, not the
          # classic `exit` string.
          "$logout")   hyprctl dispatch 'hl.dsp.exit()' ;;
          "$suspend")  hyprlock & systemctl suspend ;;
      esac
    '';
  };

  toggleWaybar = pkgs.writeShellApplication {
    name = "toggle-waybar";
    runtimeInputs = [pkgs.procps pkgs.waybar];
    text = ''
      if pgrep waybar > /dev/null; then
        pkill waybar
      else
        waybar &
      fi
    '';
  };

  toggleMic = pkgs.writeShellApplication {
    name = "toggle-mic";
    runtimeInputs = [pkgs.wireplumber pkgs.gnugrep pkgs.dunst];
    text = ''
      wpctl set-mute @DEFAULT_SOURCE@ toggle
      if wpctl get-volume @DEFAULT_SOURCE@ | grep -q "MUTED"; then
        dunstify "Mic Status" "Microphone is now muted"
      else
        dunstify "Mic Status" "Microphone is now unmuted"
      fi
    '';
  };
}
