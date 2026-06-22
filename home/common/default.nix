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

  programs.home-manager.enable = true;
}
