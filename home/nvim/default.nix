{lib, ...}: let
  enableNotes = true;
  enableLatex = true;
  enableJupyter = false;
  enableClojure = false;
in {
  imports =
    [./core.nix]
    ++ lib.optionals enableNotes [./extra/notes.nix]
    ++ lib.optionals enableJupyter [./extra/jupyter.nix]
    ++ lib.optionals enableLatex [./extra/latex.nix]
    ++ lib.optionals enableClojure [./extra/clojure.nix];

  programs.nvf.enable = true;
}
