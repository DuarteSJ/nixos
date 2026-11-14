# Laptop home config: ../common plus desktop, apps, GUI packages.
{inputs, ...}: {
  imports = [
    inputs.spicetify-nix.homeManagerModules.default

    ../common

    ./packages.nix
    ./desktop
    ./shell
    ./terminal
    ./nvim
    ./apps
    ./scripts
  ];
}
