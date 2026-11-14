# Extras on top of ../../common/nvim.
{lib, ...}: let
  enableNotes = true;
  enableLatex = true;
  enableJupyter = false;
in {
  imports =
    lib.optionals enableNotes [./extra/notes.nix]
    ++ lib.optionals enableJupyter [./extra/jupyter.nix]
    ++ lib.optionals enableLatex [./extra/latex.nix];
}
