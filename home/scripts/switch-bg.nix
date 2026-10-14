# Puts the `wallpaper` script on PATH (`wallpaper next` cycles the focused
# monitor; bound to Super+Shift+N).  The script itself lives with the
# Hyprland wallpaper code in ../desktop/hyprland/wallpaper.nix, which also
# runs `wallpaper apply` on every config load — one copy of the list,
# orientation and state logic.
{
  config,
  osConfig,
  pkgs,
  notifyPkg,
  ...
}: let
  wallpaper = import ../desktop/hyprland/wallpaper.nix {
    inherit pkgs notifyPkg;
    hyprland = osConfig.programs.hyprland.package;
    themeName = config.colorScheme.slug;
    wallpapersPath = config.vars.paths.wallpapers;
  };
in {
  home.packages = [wallpaper.package];
}
