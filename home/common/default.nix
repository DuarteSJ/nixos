# Home config every host gets: shell, git, editor, a few CLI tools.  Nothing
# graphical; host-specific parts live next to this directory (../laptop) and
# import this one themselves.
{inputs, ...}: {
  imports = [
    inputs.nvf.homeManagerModules.default

    ./vars.nix
    ./theme.nix
    ./environment.nix
    ./packages.nix
    ./git.nix

    ./terminal
    ./nvim
  ];
}
