{ pkgs, ... }:

{
  imports = [
    ./alt-tab.nix
    ./switch-bg.nix
    ./timer.nix
    ./screenshot.nix
    ./pydev.nix
    ./invis-cava.nix
  ];
}

