{pkgs, ...}: {
  # Single cursor source -> GTK, X11/XCursor, and Hyprland (hyprcursor).
  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
  };
}
