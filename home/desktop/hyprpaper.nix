_: {
  # Wallpapers are set (and updated on hotplug) by the monitor-manager
  # script under hyprland/, which uses hyprpaper IPC.  This file just
  # enables the daemon with IPC on; no static preload/wallpaper entries
  # are needed here.
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
    };
  };
}
