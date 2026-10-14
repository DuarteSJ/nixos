{pkgs, ...}: {
  networking = {
    networkmanager = {
      enable = true;
      # OpenVPN through NetworkManager, so the pushed DNS lands in resolved
      # as a per-link server (a bare `openvpn` binary never told resolved).
      # Import a profile with `nmcli connection import type openvpn file x.ovpn`.
      plugins = [pkgs.networkmanager-openvpn];
    };
    # Becomes resolved's global DNS= (settings.Resolve.DNS defaults to this).
    nameservers = ["1.1.1.1" "8.8.8.8"];
  };

  # Global DNS= alone is just one more server next to the DHCP-supplied
  # router on the default-route link, and resolved answered from whichever
  # replied (in practice the router).  The route-only root domain `~.` on the
  # global scope makes every lookup match it, so links without a more
  # specific domain (the plain DHCP router) are no longer asked.  Names under
  # a link's own search/VPN domain (e.g. `*.Home`, a VPN's corp domain) are
  # a longer match and still go to that link's server.
  # (Chosen over NetworkManager `dns=none`/ignore-auto-dns, which would also
  # drop those per-link/VPN domains.)
  services.resolved = {
    enable = true;
    settings.Resolve.Domains = ["~."];
  };
}
