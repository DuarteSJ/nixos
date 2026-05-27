{inputs, ...}: {
  home = {
    username = "duartesj";
    homeDirectory = "/home/duartesj";
    stateVersion = "25.11";
  };

  imports = [
    inputs.spicetify-nix.homeManagerModules.default
    inputs.nvf.homeManagerModules.default
    ./theme.nix
    ./vars.nix
    ./environment.nix
    ./packages.nix
    ./git.nix
    ./scripts
    ./apps
    ./desktop
    ./terminal
    ./nvim
  ];

  programs.home-manager.enable = true;
}
