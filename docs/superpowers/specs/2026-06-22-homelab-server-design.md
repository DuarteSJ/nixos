# Homelab Server + Flake Restructure — Design

Date: 2026-06-22
Status: Approved (pending spec review)

## Goal

Turn an old laptop into a headless NixOS homelab server named `homelab`.
General-purpose homelab (no fixed service set yet), reachable by SSH on the LAN
and remotely via Tailscale. Restructure the existing single-host flake into a
multi-host `hosts/` + `modules/` layout so the current desktop and the new
server share common configuration without duplication. Deploy to the server
remotely from the desktop.

Non-goals: no specific self-hosted apps (media, *arr, Nextcloud, etc.) in this
phase. The base is built to add them later.

## Decisions (locked)

- Layout: full restructure into `hosts/` + `modules/` (option B).
- Remote access: SSH on LAN **and** from anywhere via Tailscale.
- Deploy: remotely from desktop via `nixos-rebuild --target-host`.
- Laptop: wiped and clean-installed with minimal NixOS first.
- Host rename: the existing desktop host `nixos` is renamed to `desktop`.
- SSH identity: reuse the existing desktop identity keypair (one key per client
  device). No new per-destination key.

## Target Directory Layout

```
flake.nix                      # mkHost helper, iterates host definitions
flake.lock
hosts/
  desktop/
    default.nix                # desktop-only system config (was system/configuration.nix)
    hardware-configuration.nix # moved from system/
  homelab/
    default.nix                # server-only system config
    hardware-configuration.nix # generated on the laptop after clean install
modules/
  common/
    default.nix                # imports the three below
    nix.nix                    # experimental-features, gc, auto-optimise-store
    users.nix                  # duartesj normal user, zsh shell, wheel group, authorizedKeys
    locale.nix                 # time.timeZone, i18n locale settings
  desktop/
    default.nix                # nvidia, hyprland, pipewire, printing, bluetooth, udev rule, session vars
home/
  common/
    default.nix                # headless-safe HM: git, nvim, terminal/shell pkgs
    (git.nix, nvim/, terminal/ moved here)
  desktop/
    default.nix                # GUI HM: current home/desktop, apps, theme, scripts, spicetify, vars, environment, packages
  profiles/
    desktop.nix                # imports home/common + home/desktop
    server.nix                 # imports home/common only
```

The desktop's behavior must be unchanged after the move: same modules, only
relocated and split into shared (`modules/common`, `home/common`) vs
desktop-only (`modules/desktop`, `home/desktop`).

## flake.nix

- Add a `mkHost { hostname, system ? "x86_64-linux" }` helper that returns a
  `nixpkgs.lib.nixosSystem` with `specialArgs = { inherit inputs; }`, the
  Home Manager NixOS module, and `nixpkgs.config.allowUnfree = true`.
- Each host's `hosts/<name>/default.nix` imports its hardware config, the
  relevant `modules/*`, and wires the matching `home/profiles/*` into
  `home-manager.users.duartesj`.
- Outputs:
  - `nixosConfigurations.desktop` (renamed from `nixos`).
  - `nixosConfigurations.homelab` (new).
- Server-irrelevant inputs (e.g. `spicetify-nix`) are only referenced from the
  desktop profile, so evaluating `homelab` does not pull desktop-only GUI
  closures.

### Consequence of rename
Desktop rebuilds change from `--flake .#nixos` to `--flake .#desktop`. Any
alias/script that hardcodes `nixos` must be updated (checked during
implementation).

## modules/common (shared)

Extracted verbatim from the current `system/configuration.nix`:

- `nix.nix` — `experimental-features = ["nix-command" "flakes"]`,
  `auto-optimise-store = true`, weekly gc with `--delete-older-than 30d`.
- `users.nix` — `users.users.duartesj` (isNormalUser, description, `shell =
  pkgs.zsh`, `extraGroups = ["wheel"]`; `networkmanager` group stays only where
  NetworkManager is enabled), `programs.zsh.enable = true`,
  `users.users.duartesj.openssh.authorizedKeys.keys = [ <desktop pubkey> ]`.
- `locale.nix` — `time.timeZone = "Europe/Lisbon"`, `i18n.defaultLocale`,
  `extraLocaleSettings` (pt_PT).
- `system.stateVersion` stays per-host (desktop keeps `26.05`; homelab set to
  the channel it is installed from).

## modules/desktop (desktop-only)

Everything desktop-specific from the current config: `services.xserver.videoDrivers`,
the full `hardware` nvidia/bluetooth/graphics block, `programs.hyprland`,
`services.{printing,pipewire,resolved}`, the vial `udev.extraRules`,
`environment.sessionVariables` (NIXOS_OZONE_WL, LIBVA_DRIVER_NAME, NVD_BACKEND),
`security.rtkit.enable`. Boot loader (GRUB + Windows entry) stays in
`hosts/desktop/default.nix` since it is host hardware specific.

## hosts/homelab/default.nix (server)

- Imports: `modules/common`, its `hardware-configuration.nix`,
  `home/profiles/server.nix`.
- Networking: `networking.hostName = "homelab"`; NetworkManager or plain
  `networking` (decided at implementation based on whether laptop uses wifi —
  wifi server likely wants `networkmanager` or `wpa_supplicant`).
- Boot loader: systemd-boot if the laptop is UEFI (simpler than GRUB; no
  Windows dual-boot needed on a wiped server), set during implementation from
  the installed hardware.
- `services.openssh = { enable = true; settings.PasswordAuthentication = false;
  settings.PermitRootLogin = "no"; settings.KbdInteractiveAuthentication =
  false; }`.
- `services.tailscale.enable = true;`.
- `services.logind = { lidSwitch = "ignore"; lidSwitchExternalPower =
  "ignore"; }` so the laptop runs with the lid closed.
- `networking.firewall` — default deny inbound; allow tcp 22 on the LAN
  interface and trust the `tailscale0` interface; allow Tailscale UDP port.
- `nix.settings.trusted-users = [ "duartesj" ]` so remote `nixos-rebuild
  --target-host` can write to the store.
- No GUI, audio, printing, nvidia, or bluetooth.

## home/profiles/server.nix

Headless HM profile: imports `home/common` only (git, nvim, terminal/shell).
`home.username = "duartesj"`, `home.homeDirectory = "/home/duartesj"`,
`home.stateVersion` per channel. No `home/desktop` import, so no Hyprland,
waybar, spicetify, theme/cursor, or GUI packages are evaluated.

## Install + Deploy Flow

1. **Clean install on the laptop:**
   - Boot the NixOS minimal ISO.
   - Partition (UEFI: ESP + root; optional swap), format, mount.
   - `nixos-generate-config --root /mnt`.
   - Set a temporary root/user password, enable sshd in the generated
     `configuration.nix`, `nixos-install`, reboot.
2. **Capture hardware config:** copy the laptop's generated
   `/etc/nixos/hardware-configuration.nix` into `hosts/homelab/` in this repo
   (via scp/Tailscale once reachable).
3. **First flake deploy from desktop:**
   `nixos-rebuild switch --flake .#homelab --target-host duartesj@homelab \
     --build-host localhost --use-remote-sudo`
   (build on the fast desktop, activate on the laptop).
4. **Join the tailnet on the laptop:** `sudo tailscale up` (authenticate once).
5. Verify: SSH from desktop over LAN and over Tailscale; confirm lid-closed
   operation; confirm subsequent `nixos-rebuild --target-host` works key-only.

## Verification / Success Criteria

- `nix flake check` and `nixos-rebuild build --flake .#desktop` succeed and the
  desktop closure is unchanged (no GUI regressions after the restructure).
- `nixos-rebuild build --flake .#homelab` succeeds and its closure contains no
  Hyprland/nvidia/pipewire desktop closures.
- SSH into `homelab` works key-only from the LAN and over Tailscale; password
  auth and root login are refused.
- Laptop stays up with the lid closed.
- A second remote `nixos-rebuild --target-host` from the desktop applies a
  trivial change without a password prompt.

## Risks / Open Items

- Host rename can break hardcoded `#nixos` references — grep and fix during
  implementation.
- Laptop networking (wifi vs ethernet) and boot mode (UEFI vs BIOS) are unknown
  until the hardware config is generated; the homelab host file is finalized
  then.
- Migrating the desktop config risks accidental behavior change; the unchanged-
  closure check in Verification guards against it.
