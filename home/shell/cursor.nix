{
  pkgs,
  config,
  ...
}: {
  # Single cursor source -> GTK, X11/XCursor, and Hyprland (hyprcursor).
  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = config.vars.cursor.name;
    size = config.vars.cursor.size;
    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
  };
}
