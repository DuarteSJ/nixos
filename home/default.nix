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

  # username/homeDirectory come from users.users via the NixOS module.
  home.stateVersion = "26.05";
}
