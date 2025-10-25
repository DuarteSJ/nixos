{ pkgs, ... }:

{
  imports = [
    ./spicetify.nix
    ./firefox.nix
    ./vesktop.nix
    ./zathura.nix
  ];
}
