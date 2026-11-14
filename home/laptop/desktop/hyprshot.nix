_: {
  # Hyprland screenshot tool, bound to $mainMod+X (region).
  # Saves to HYPRSHOT_DIR and copies to clipboard.
  programs.hyprshot = {
    enable = true;
    saveLocation = "$HOME/Pictures/screenshots";
  };
}
