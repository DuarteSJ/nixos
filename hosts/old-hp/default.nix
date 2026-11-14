# Old AMD HP laptop running as a headless server (was "homelab"; restored
# from git history, removed in 40fe62f).
_: {
  imports = [
    ./hardware-configuration.nix
    ../../system/nix.nix
    ../../system/users.nix
    ../../system/locale.nix
  ];

  system.stateVersion = "26.05";

  # UEFI bootloader (the generated hardware-configuration.nix does not set one).
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "old-hp";
    # Old laptop almost certainly uses wifi; NetworkManager is the simplest path.
    networkmanager.enable = true;
    # The ISP's DHCP-provided IPv6 resolver flaps, so glibc round-robins onto a
    # dead server and lookups fail intermittently. Take DNS away from
    # NetworkManager entirely (`dns = "none"`) so NixOS writes resolv.conf from
    # `nameservers` below — only reliable public resolvers, no flaky DHCP ones.
    networkmanager.dns = "none";
    nameservers = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];

    firewall = {
      enable = true;
      allowedTCPPorts = [22];
      trustedInterfaces = ["tailscale0"];
      allowedUDPPorts = [41641];
      checkReversePath = "loose";
    };
  };

  # Key-only SSH below: without this the box is unreachable.
  users.users.duartesj.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKaUcoEtcYjJQVwOE8hjF9JJ+HMAe4/PsjIJv5M6u1HN ddduarte@sapo.pt"
  ];

  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    # Reachable off-LAN. Run `tailscale up` once to authenticate.
    tailscale.enable = true;

    # Run with the lid closed.
    logind.settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
    };
  };

  # Allow remote `nixos-rebuild --target-host` to write to the store.
  nix.settings.trusted-users = ["root" "duartesj"];

  # Passwordless sudo for the deploy user so `nixos-rebuild --target-host
  # --sudo` runs non-interactively. Acceptable here: single-user box, key-only
  # SSH, behind firewall + Tailscale.
  security.sudo.wheelNeedsPassword = false;

  home-manager.users.duartesj = import ./home.nix;
}
