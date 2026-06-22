{...}: {
  # Tailscale on every host: the server is reachable off-LAN, and clients
  # (desktop) join the same tailnet to reach it. Run `tailscale up` once per
  # machine to authenticate.
  services.tailscale.enable = true;
}
