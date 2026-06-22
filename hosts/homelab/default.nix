{...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/common
  ];

  system.stateVersion = "26.05";

  # UEFI bootloader (the generated hardware-configuration.nix does not set one).
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "homelab";
    # Old laptop almost certainly uses wifi; NetworkManager is the simplest path.
    networkmanager.enable = true;
    # The ISP's DHCP-provided IPv6 resolver flaps, so glibc round-robins onto a
    # dead server and lookups fail intermittently. Take DNS away from
    # NetworkManager entirely (`dns = "none"`) so NixOS writes resolv.conf from
    # `nameservers` below — only reliable public resolvers, no flaky DHCP ones.
    networkmanager.dns = "none";
    nameservers = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];
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

  # Run with the lid closed.
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
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

  # Passwordless sudo for the deploy user so `nixos-rebuild --target-host
  # --use-remote-sudo` runs non-interactively. Acceptable here: single-user
  # box, key-only SSH, behind firewall + Tailscale.
  security.sudo.wheelNeedsPassword = false;

  home-manager.users.duartesj = import ../../home/profiles/server.nix;
}
