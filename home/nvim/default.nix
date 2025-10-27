{ config, pkgs, lib, ... }: 

let
    # Toggle optional modules
    enableJupyter = false;
    enableLatex = true;
    enableNotes = true;
in
{
    imports = [
        ./core.nix
        ./languages.nix
        ./ui.nix
        ./keymaps.nix
    ] ++ lib.optionals enableNotes [ ./extra/notes.nix ]
      ++ lib.optionals enableJupyter [ ./extra/jupyter.nix ]
      ++ lib.optionals enableLatex [ ./extra/latex.nix ];

    programs.nvf.enable = true;
}
