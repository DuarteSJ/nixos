{...}: {
  # Hyprland screenshot tool. Mode chosen via rofi menu bound to $mainMod+X.
  # Saves to HYPRSHOT_DIR and copies to clipboard.
  programs.hyprshot = {
    enable = true;
    saveLocation = "$HOME/Pictures/screenshots";
  };
}
