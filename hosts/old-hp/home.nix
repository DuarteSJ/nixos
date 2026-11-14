# Headless subset of ../../home (was home/profiles/server.nix + home/common):
# shell, git, nvim, a few CLI tools.  No desktop, apps or GUI packages.
{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.nvf.homeManagerModules.default

    ../../home/vars.nix
    ../../home/theme.nix
    ../../home/environment.nix
    ../../home/git.nix

    ../../home/terminal/shell
    ../../home/terminal/btop.nix
    ../../home/terminal/fastfetch.nix
    ../../home/nvim
  ];

  # username/homeDirectory come from users.users via the NixOS module.
  home.stateVersion = "26.05";

  # home/packages.nix is mostly desktop software; keep the old server set.
  home.packages = with pkgs; [
    gh
    curl
    eza
    ripgrep
    jq
    zip
    unzip
  ];
}
