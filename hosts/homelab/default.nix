{...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/common
  ];

  system.stateVersion = "26.05";

  networking = {
    hostName = "homelab";
    # Old laptop almost certainly uses wifi; NetworkManager is the simplest path.
    networkmanager.enable = true;
    nameservers = ["1.1.1.1" "8.8.8.8"];
  };

  # duartesj needs networkmanager here too (common only grants wheel).
  users.users.duartesj.extraGroups = ["networkmanager"];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.tailscale.enable = true;

  # Run with the lid closed.
  services.logind = {
    lidSwitch = "ignore";
    lidSwitchExternalPower = "ignore";
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [22];
    trustedInterfaces = ["tailscale0"];
    allowedUDPPorts = [41641];
    checkReversePath = "loose";
  };

  # Allow remote `nixos-rebuild --target-host` to write to the store.
  nix.settings.trusted-users = ["root" "duartesj"];

  home-manager.users.duartesj = import ../../home/profiles/server.nix;
}
