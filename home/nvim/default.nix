{lib, ...}: let
  enableNotes = true;
  enableLatex = true;
  enableJupyter = false;
in {
  imports =
    [./core.nix]
    ++ lib.optionals enableNotes [./extra/notes.nix]
    ++ lib.optionals enableJupyter [./extra/jupyter.nix]
    ++ lib.optionals enableLatex [./extra/latex.nix];

  programs.nvf.enable = true;
}
