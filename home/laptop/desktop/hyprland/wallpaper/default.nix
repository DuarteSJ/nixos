# Wallpapers: the hyprpaper daemon, plus the `wallpaper` script (./script.nix)
# on PATH (`wallpaper next` cycles the focused monitor; Super+Shift+N).
#
# Images are pushed over hyprpaper's IPC (on by default) by that script, run
# on every Hyprland config load (../default.nix) and from the keybind, so
# there are no static preload/wallpaper entries here.  ../default.nix imports
# the same script; both calls build the same derivation.
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
    themeName = config.colorScheme.slug;
    wallpapersPath = config.vars.paths.wallpapers;
  };
in {
  services.hyprpaper = {
    enable = true;
    settings.splash = false;
  };

  home.packages = [wallpaper.package];
}
