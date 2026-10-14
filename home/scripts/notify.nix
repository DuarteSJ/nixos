{pkgs, ...}: let
  notifyPkg = pkgs.callPackage ./notify-pkg.nix {};
in {
  home.packages = [notifyPkg];
  # Shared with every script that calls `notify` (runtimeInputs / PATH).
  _module.args.notifyPkg = notifyPkg;
}
