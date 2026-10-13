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
