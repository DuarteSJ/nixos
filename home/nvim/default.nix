{lib, ...}: let
  enableNotes = true;
  enableLatex = true;
  enableJupyter = true;
  enableClojure = true;
in {
  imports =
    [./core.nix]
    ++ lib.optionals enableNotes [./extra/notes.nix]
    ++ lib.optionals enableJupyter [./extra/jupyter.nix]
    ++ lib.optionals enableLatex [./extra/latex.nix]
    ++ lib.optionals enableClojure [./extra/clojure.nix];

  programs.nvf.enable = true;
}
