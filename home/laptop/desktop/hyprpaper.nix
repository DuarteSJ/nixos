_: {
  # Just the daemon.  Wallpapers are pushed over hyprpaper's IPC (on by
  # default) by the `wallpaper` script in hyprland/wallpaper.nix, run on
  # every Hyprland config load and from Super+Shift+N, so there are no
  # static preload/wallpaper entries here.
  services.hyprpaper = {
    enable = true;
    settings.splash = false;
  };
}
