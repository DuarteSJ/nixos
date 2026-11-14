# Shell scripts invoked from keybinds.
# writeShellApplication injects a deterministic PATH (runtimeInputs), enables
# strict mode (set -euo pipefail) and runs shellcheck at build time.  Call
# sites reference these via `lib.getExe` (they're packages, not bare files).
{
  pkgs,
  notifyPkg,
}: {
  toggleMic = pkgs.writeShellApplication {
    name = "toggle-mic";
    runtimeInputs = [pkgs.wireplumber pkgs.gnugrep notifyPkg];
    text = ''
      wpctl set-mute @DEFAULT_SOURCE@ toggle
      if wpctl get-volume @DEFAULT_SOURCE@ | grep -q "MUTED"; then
        notify -r mic "Mic Status" "Microphone is now muted"
      else
        notify -r mic "Mic Status" "Microphone is now unmuted"
      fi
    '';
  };
}
