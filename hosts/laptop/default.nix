{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
    ./hardware.nix
    ./network.nix
    ./hibernate.nix
    ../../system/nix.nix
    ../../system/users.nix
    ../../system/locale.nix
  ];

  networking.hostName = "laptop";
  system.stateVersion = "26.05";

  programs = {
    hyprland.enable = true;
    steam.enable = true;
    # Only active while a `gamemoderun`-wrapped process runs (set per game in
    # Steam launch options).
    gamemode.enable = true;
  };

  # bonk-reroll (home/apps/bonk-reroll) presses quick reset through a virtual
  # keyboard. (Reading Megabonk's memory needs no sysctl: the game opts in to
  # being traced itself, verified with ptrace_scope = 1.)
  hardware.uinput.enable = true;

  # Groups created by gamemode and uinput above.
  users.users.duartesj.extraGroups = ["gamemode" "uinput"];

  services.printing.enable = true;

  # PAM service for the quickshell lock screen (home/shell/quickshell,
  # LockScreen.qml checks the password with PamContext { config: "qs-lock" }).
  security.pam.services.qs-lock = {};

  # (OpenVPN comes via the NetworkManager plugin in network.nix.)
  environment.systemPackages = [pkgs.android-tools];
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  home-manager.users.duartesj = import ../../home;
}
