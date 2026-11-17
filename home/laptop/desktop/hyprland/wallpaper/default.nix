# Wallpapers: the hyprpaper daemon, plus the `wallpaper` script (./script.nix)
# on PATH (`wallpaper next` cycles the focused monitor; Super+Shift+N).
#
# Images are pushed over hyprpaper's IPC (on by default) by that script, run
# on every Hyprland config load (../default.nix) and from the keybind, so
# there are no static preload/wallpaper entries here.  The script is built
# once here and handed to ../default.nix as the `wallpaper` module arg.
{
  config,
  osConfig,
  pkgs,
  notifyPkg,
  ...
}: let
  wallpaper = import ./script.nix {
    inherit pkgs notifyPkg;
    hyprland = osConfig.programs.hyprland.package;
    wallpapersDir = config.colorScheme.wallpapers;
  };
in {
  _module.args.wallpaper = wallpaper;

  services.hyprpaper = {
    enable = true;
    settings.splash = false;
  };

  home.packages = [wallpaper.package];
}
