{
  config,
  pkgs,
  lib,
  ...
}: let
  # Optional modules
  enableJupyter = false;
  enableLatex = true;
  enableNotes = true;
  enableClojure = true;
in {
  imports =
    [
      ./core.nix
      ./languages.nix
      ./ui.nix
      ./keymaps.nix
    ]
    ++ lib.optionals enableNotes [./extra/notes.nix]
    ++ lib.optionals enableJupyter [./extra/jupyter.nix]
    ++ lib.optionals enableLatex [./extra/latex.nix]
    ++ lib.optionals enableClojure [./extra/clojure.nix];

  programs.nvf.enable = true;
}
