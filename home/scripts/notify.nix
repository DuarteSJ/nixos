{pkgs, ...}: {
  home.packages = [(pkgs.callPackage ./notify-pkg.nix {})];
}
