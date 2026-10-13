# Generated aerial-lagoon wallpaper for the "lagoon" scheme: rich, textured
# colour so the liquid-glass blur has something to diffuse.
#
# Installed as real files (not home.file symlinks): the wallpaper picker and
# switch-bg look for images with `find -type f`, which skips symlinks.
{
  config,
  lib,
  pkgs,
  ...
}: let
  dir = "${config.vars.paths.wallpapers}/lagoon";
  horizontal = pkgs.callPackage ./package.nix {};
  vertical = pkgs.callPackage ./package.nix {
    width = 1080;
    height = 1920;
  };
in {
  home.activation.lagoonWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run install -Dm644 ${horizontal} "${dir}/horizontal/lagoon.png"
    run install -Dm644 ${vertical} "${dir}/vertical/lagoon.png"
  '';
}
