# Shell scripts invoked from keybinds.
{pkgs}: {
  rofi-launcher = pkgs.writeShellScript "rofi-launcher" ''
    set -euo pipefail
    rofi -show drun
  '';

  rofi-powermenu = pkgs.writeShellScript "rofi-powermenu" ''
    set -euo pipefail
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

  toggleWaybar = pkgs.writeShellScript "toggle-waybar" ''
    set -euo pipefail
    if pgrep waybar > /dev/null; then
      pkill waybar
    else
      waybar &
    fi
  '';

  toggleMic = pkgs.writeShellScript "toggle-mic" ''
    set -euo pipefail
    wpctl set-mute @DEFAULT_SOURCE@ toggle
    if wpctl get-volume @DEFAULT_SOURCE@ | grep -q "MUTED"; then
      dunstify "Mic Status" "Microphone is now muted"
    else
      dunstify "Mic Status" "Microphone is now unmuted"
    fi
  '';
}
