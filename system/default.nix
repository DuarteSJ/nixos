{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
    ./hardware.nix
    ./network.nix
    ./nix.nix
    ./users.nix
    ./locale.nix
    ./keyboard.nix
  ];

  networking.hostName = "desktop";
  system.stateVersion = "26.05";

  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    steam.enable = true;
    # Only active while a `gamemoderun`-wrapped process runs (set per game in
    # Steam launch options).
    gamemode.enable = true;
  };

  services.printing.enable = true;

  environment.systemPackages = [pkgs.openvpn pkgs.android-tools];
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  home-manager.users.duartesj = import ../home;
}
