# Graphical session: Hyprland (compositor, monitors, wallpaper), the
# quickshell desktop shell (bar, launcher, notifications, lock screen), the
# hypr* helper daemons, and the cursor theme.
{...}: {
  imports = [
    ./hyprland
    ./quickshell
    ./cursor.nix
    ./hypridle.nix
    ./hyprshot.nix
    ./hyprsunset.nix
  ];
}
