{inputs, ...}: {
  home.username = "duartesj";
  home.homeDirectory = "/home/duartesj";
  home.stateVersion = "24.11";

  imports = [
    inputs.nix-colors.homeManagerModules.default
    inputs.spicetify-nix.homeManagerModules.default
    inputs.nvf.homeManagerModules.default
    ./environment.nix
    ./packages.nix
    ./git.nix
    ./scripts
    ./apps
    ./desktop
    ./scripts
    ./terminal
    ./nvim
  ];

  colorScheme = inputs.nix-colors.colorSchemes.nord;

  programs.home-manager.enable = true;
}
