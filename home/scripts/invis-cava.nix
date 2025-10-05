{ config, pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellScriptBin "invis-cava" ''
    alacritty -o font.size=4 -o window.padding.x=2 -o window.padding.y=2 -o window.opacity=0.0 --class invis-cava -e zsh -c "cava; exec zsh"
    '')
  ];
}
