# Base editor.  Optional extras (notes, LaTeX, Jupyter) are per host:
# ../../laptop/nvim.
{...}: {
  imports = [
    ./core.nix
    ./keymaps.nix
    ./autocmds.nix
  ];

  programs.nvf.enable = true;
}
