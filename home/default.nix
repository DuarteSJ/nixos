{inputs, ...}: {
  imports = [
    inputs.nvf.homeManagerModules.default
    inputs.spicetify-nix.homeManagerModules.default

    ./vars.nix
    ./theme.nix
    ./environment.nix
    ./packages.nix
    ./git.nix

    ./desktop
    ./shell
    ./terminal
    ./nvim
    ./apps
    ./scripts
  ];

  home = {
    username = "duartesj";
    homeDirectory = "/home/duartesj";
    stateVersion = "26.05";
  };

  programs.home-manager.enable = true;
}
