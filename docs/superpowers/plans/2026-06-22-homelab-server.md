# Homelab Server + Flake Restructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure the single-host NixOS flake into a `hosts/` + `modules/` multi-host layout and add a headless `homelab` server (SSH + Tailscale) running on a wiped old laptop, deployed remotely from the desktop.

**Architecture:** Shared NixOS config lives in `modules/common`; desktop-only config in `modules/desktop`. Home Manager splits into `home/common` (headless-safe) and `home/desktop` (GUI), wired per host through `home/profiles/{desktop,server}.nix`. `flake.nix` gains an `mkHost` helper and exposes `nixosConfigurations.desktop` (renamed from `nixos`) and `nixosConfigurations.homelab`.

**Tech Stack:** Nix flakes, NixOS 26.05, home-manager, Tailscale, OpenSSH.

**Spec:** `docs/superpowers/specs/2026-06-22-homelab-server-design.md`

**Verification model:** This is Nix configuration, not unit-testable code. The "test" for each task is evaluation/build:
- `nixos-rebuild build --flake .#<host>` (builds the system closure to `./result` without activating).
- `nix store diff-closures <old> <new>` for human-readable closure comparison.
- The desktop closure MUST stay semantically unchanged across the restructure (Tasks 1-5).

**Important sequencing:** Tasks 1-6 are done now on the desktop and are fully verifiable by `build`. Task 7 (laptop install + remote deploy) happens on physical hardware and finalizes `hosts/homelab/hardware-configuration.nix`; until then the homelab host uses a placeholder hardware stub so it still evaluates.

---

### Task 0: Baseline the current desktop closure

**Files:** none (measurement only)

- [ ] **Step 1: Confirm clean tree**

Run: `git status --porcelain`
Expected: empty output (besides the already-committed spec/plan).

- [ ] **Step 2: Build the current config and record its store path**

Run:
```bash
nixos-rebuild build --flake .#nixos
readlink -f result > /tmp/desktop-baseline.path
cat /tmp/desktop-baseline.path
```
Expected: a `/nix/store/...-nixos-system-nixos-26.05...` path printed and saved. This is the reference closure the restructure must reproduce.

- [ ] **Step 3: Remove the build symlink**

Run: `rm -f result`
Expected: no error.

---

### Task 1: Create `modules/common` (shared NixOS config)

**Files:**
- Create: `modules/common/default.nix`
- Create: `modules/common/nix.nix`
- Create: `modules/common/users.nix`
- Create: `modules/common/locale.nix`

- [ ] **Step 1: Write `modules/common/nix.nix`** (extracted verbatim from `system/configuration.nix`)

```nix
{...}: {
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  nixpkgs.config.allowUnfree = true;
}
```

- [ ] **Step 2: Write `modules/common/locale.nix`**

```nix
{lib, ...}: {
  time.timeZone = "Europe/Lisbon";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = lib.genAttrs [
      "LC_ADDRESS"
      "LC_IDENTIFICATION"
      "LC_MEASUREMENT"
      "LC_MONETARY"
      "LC_NAME"
      "LC_NUMERIC"
      "LC_PAPER"
      "LC_TELEPHONE"
      "LC_TIME"
    ] (_: "pt_PT.UTF-8");
  };
}
```

- [ ] **Step 3: Write `modules/common/users.nix`**

Replace `PASTE_DESKTOP_PUBKEY_HERE` with the desktop's actual public key (`cat ~/.ssh/id_ed25519.pub`) during execution. `networkmanager` group is intentionally NOT here — it is added per-host where NetworkManager is enabled.

```nix
{pkgs, ...}: {
  users.users.duartesj = {
    isNormalUser = true;
    description = "Duarte S. Jose";
    shell = pkgs.zsh;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [
      "PASTE_DESKTOP_PUBKEY_HERE"
    ];
  };

  programs.zsh.enable = true;
}
```

- [ ] **Step 4: Write `modules/common/default.nix`**

```nix
{...}: {
  imports = [
    ./nix.nix
    ./users.nix
    ./locale.nix
  ];
}
```

- [ ] **Step 5: Commit**

```bash
git add modules/common
git commit -m "feat: add modules/common shared nixos config"
```

---

### Task 2: Create `modules/desktop` (desktop-only NixOS config)

**Files:**
- Create: `modules/desktop/default.nix`

- [ ] **Step 1: Write `modules/desktop/default.nix`**

This is every desktop-specific block lifted from `system/configuration.nix`. The `networkmanager` group is added here (desktop uses NetworkManager). Boot loader and hostname are NOT here — they move to `hosts/desktop/default.nix` (Task 3).

```nix
{
  pkgs,
  lib,
  ...
}: {
  # duartesj needs networkmanager on the desktop (added on top of common's wheel).
  users.users.duartesj.extraGroups = ["networkmanager"];

  networking = {
    networkmanager.enable = true;
    nameservers = ["1.1.1.1" "8.8.8.8"];
  };

  environment.systemPackages = [pkgs.openvpn pkgs.android-tools];

  # NVIDIA driver selection (gates the hardware.nvidia block below).
  services.xserver.videoDrivers = ["nvidia"];

  hardware = {
    bluetooth.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      modesetting.enable = true;
      open = true;
      videoAcceleration = true;
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  services = {
    resolved.enable = true;
    printing.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    udev.extraRules = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="vial:f64c2b3c", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
    '';
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
  };

  security.rtkit.enable = true;
}
```

- [ ] **Step 2: Commit**

```bash
git add modules/desktop
git commit -m "feat: add modules/desktop nixos config"
```

---

### Task 3: Create `hosts/desktop/` (boot loader, hostname, hardware, HM wiring)

**Files:**
- Create: `hosts/desktop/default.nix`
- Move: `system/hardware-configuration.nix` -> `hosts/desktop/hardware-configuration.nix`

- [ ] **Step 1: Move the hardware config with git**

Run:
```bash
mkdir -p hosts/desktop
git mv system/hardware-configuration.nix hosts/desktop/hardware-configuration.nix
```
Expected: file relocated, staged.

- [ ] **Step 2: Write `hosts/desktop/default.nix`**

Contains host-specific boot loader (GRUB + hand-maintained Windows entry, verbatim from the old config), hostname, stateVersion, the common + desktop modules, and the desktop HM profile. `inputs` is available via `specialArgs`.

```nix
{inputs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/common
    ../../modules/desktop
  ];

  system.stateVersion = "26.05";

  networking.hostName = "nixos";

  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = false;
      configurationLimit = 10;
      extraEntries = ''
        menuentry "Windows" {
          insmod part_gpt
          insmod fat
          insmod chain
          search --no-floppy --fs-uuid --set=root 7801-1D56
          chainloader /efi/Microsoft/Boot/bootmgfw.efi
        }
      '';
    };
  };

  home-manager.users.duartesj = import ../../home/profiles/desktop.nix;
}
```

NOTE: `networking.hostName` stays `"nixos"` here for now. It becomes irrelevant to the rename — the *flake attribute* is what gets renamed to `desktop` in Task 5. The OS hostname can stay `nixos` (changing it is cosmetic and out of scope).

- [ ] **Step 3: Commit**

```bash
git add hosts/desktop
git commit -m "feat: add hosts/desktop host definition"
```

---

### Task 4: Restructure `home/` into common + desktop + profiles

**Files:**
- Create: `home/common/default.nix`, `home/common/environment.nix`, `home/common/packages.nix`
- Move: `home/git.nix`, `home/nvim/`, `home/terminal/shell/`, `home/terminal/btop.nix`, `home/terminal/fastfetch.nix` -> under `home/common/`
- Create: `home/desktop/profile.nix` (aggregator) and move GUI modules under `home/desktop/`
- Create: `home/profiles/desktop.nix`, `home/profiles/server.nix`
- Delete: old `home/default.nix` (replaced by profiles)

The current `home/default.nix` imports: theme, vars, environment, packages, git, scripts, apps, desktop, terminal, nvim. We split these into headless-safe (common) and GUI (desktop).

Classification:
- **common (headless):** `git.nix`, `nvim/`, `terminal/shell/` (zsh/bash/starship/direnv), `terminal/btop.nix`, `terminal/fastfetch.nix`, a decoupled `environment.nix`, a slim `packages.nix`.
- **desktop (GUI):** `theme.nix`, `vars.nix`, `scripts/`, `apps/`, `desktop/`, `terminal/alacritty.nix`, `terminal/cava.nix`, the full GUI `packages.nix`.

- [ ] **Step 1: Create the common HM tree and move headless modules**

Run:
```bash
mkdir -p home/common/terminal home/profiles
git mv home/git.nix       home/common/git.nix
git mv home/nvim          home/common/nvim
git mv home/terminal/shell      home/common/terminal/shell
git mv home/terminal/btop.nix   home/common/terminal/btop.nix
git mv home/terminal/fastfetch.nix home/common/terminal/fastfetch.nix
```
Expected: files relocated, staged.

- [ ] **Step 2: Write `home/common/terminal/default.nix`**

```nix
{...}: {
  imports = [
    ./shell
    ./btop.nix
    ./fastfetch.nix
  ];
}
```

- [ ] **Step 3: Write decoupled `home/common/environment.nix`**

Decoupled from `config.vars.editor` (vars is GUI-only and stays in desktop). EDITOR is hardcoded to nvim, which equals the previous `vars.editor` default.

```nix
{...}: {
  home.sessionPath = ["$HOME/.local/bin"];

  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
```

- [ ] **Step 4: Write slim `home/common/packages.nix`** (headless CLI tools only)

```nix
{pkgs, ...}: {
  home.packages = with pkgs; [
    gh
    curl
    eza
    ripgrep
    jq
    fastfetch
  ];
}
```

- [ ] **Step 5: Write `home/common/default.nix`**

```nix
{...}: {
  imports = [
    ./environment.nix
    ./packages.nix
    ./git.nix
    ./terminal
    ./nvim
  ];

  programs.home-manager.enable = true;
}
```

- [ ] **Step 6: Move GUI modules into `home/desktop/` and split terminal**

The GUI modules `theme.nix`, `vars.nix`, `scripts/`, `apps/`, and the existing `desktop/` subtree already live under `home/`. Move the home-root GUI files into `home/desktop/` and relocate the GUI terminal pieces:

```bash
git mv home/theme.nix        home/desktop/theme.nix
git mv home/vars.nix         home/desktop/vars.nix
git mv home/scripts          home/desktop/scripts
git mv home/apps             home/desktop/apps
git mv home/terminal/alacritty.nix home/desktop/alacritty.nix
git mv home/terminal/cava.nix      home/desktop/cava.nix
git mv home/packages.nix     home/desktop/packages.nix
```
Note: `home/desktop/` already exists (dunst, hyprland, waybar, etc.) with its own `default.nix`; we are adding files alongside it. The remaining `home/terminal/` dir now only had a `default.nix` referencing moved files — it is removed in Step 8.

- [ ] **Step 7: Trim the GUI list in `home/desktop/packages.nix`**

Remove the CLI tools now provided by `home/common/packages.nix` to avoid duplication. Edit `home/desktop/packages.nix` and delete these lines from the `with pkgs; [...]` list: `gh`, `curl`, `eza`, `fastfetch`, `ripgrep`, `jq`. Keep everything else (GUI apps, fonts, nvidia-vaapi-driver, texlive, the claude-code input, etc.).

- [ ] **Step 8: Write the desktop HM aggregator `home/desktop/default.nix`**

`home/desktop/default.nix` currently aggregates only the window-manager GUI pieces (dunst, hyprland, hyprlock, waybar, ...). Read it first, then extend its `imports` list to also pull the relocated GUI modules. The resulting file's `imports` must include the WM pieces AND: `./theme.nix ./vars.nix ./scripts ./apps ./packages.nix ./alacritty.nix ./cava.nix`. Also remove the now-empty `home/terminal/`:

```bash
git rm home/terminal/default.nix
rmdir home/terminal 2>/dev/null || true
```

Resulting `home/desktop/default.nix` imports (merge with existing WM entries — do not drop any existing line):
```nix
  imports = [
    inputs.spicetify-nix.homeManagerModules.default
    # existing WM modules (dunst, hyprland, hyprlock, hyprpaper, hyprshot,
    # hyprsunset, monitors, rofi, waybar) stay as they are
    ./dunst.nix
    ./hyprland
    ./hyprlock.nix
    ./hyprpaper.nix
    ./hyprshot.nix
    ./hyprsunset.nix
    ./monitors.nix
    ./rofi.nix
    ./waybar.nix
    # relocated GUI modules
    ./theme.nix
    ./vars.nix
    ./scripts
    ./apps
    ./packages.nix
    ./alacritty.nix
    ./cava.nix
  ];
```
(`apps/spicetify.nix` requires the spicetify module import — keep `inputs.spicetify-nix...` here. Confirm `apps/default.nix` already imports spicetify; if `home/desktop/default.nix` did not previously import the spicetify module, add it as shown.)

- [ ] **Step 9: Write `home/profiles/desktop.nix`**

```nix
{...}: {
  imports = [
    ../common
    ../desktop
  ];

  home = {
    username = "duartesj";
    homeDirectory = "/home/duartesj";
    stateVersion = "26.05";
  };
}
```

- [ ] **Step 10: Write `home/profiles/server.nix`**

```nix
{...}: {
  imports = [
    ../common
  ];

  home = {
    username = "duartesj";
    homeDirectory = "/home/duartesj";
    stateVersion = "26.05";
  };
}
```

- [ ] **Step 11: Delete the obsolete `home/default.nix`**

Its role (imports + home identity) is now split between `home/common/default.nix` and the two profiles.

```bash
git rm home/default.nix
```

- [ ] **Step 12: Commit**

```bash
git add -A home
git commit -m "refactor: split home-manager into common/desktop/profiles"
```

---

### Task 5: Rewrite `flake.nix` with `mkHost` and rename host to `desktop`

**Files:**
- Modify: `flake.nix`
- Remove: `system/configuration.nix` (fully superseded by hosts/ + modules/)

- [ ] **Step 1: Delete the superseded monolith**

Run:
```bash
git rm system/configuration.nix
rmdir system 2>/dev/null || true
```
Expected: `system/` removed (both its files moved/deleted by now).

- [ ] **Step 2: Rewrite `flake.nix`**

Keep the existing `inputs` block unchanged (nixpkgs, spicetify-nix, home-manager, nvf, claude-code). Replace the `outputs` block with an `mkHost` helper. `home-manager.useGlobalPkgs`/`useUserPackages` + `allowUnfree` are applied globally; per-host HM wiring lives in each host file.

```nix
  outputs = {
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    system = "x86_64-linux";

    mkHost = hostPath:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules = [
          hostPath
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {inherit inputs;};
            };
          }
        ];
      };
  in {
    nixosConfigurations = {
      desktop = mkHost ./hosts/desktop/default.nix;
      homelab = mkHost ./hosts/homelab/default.nix;
    };
  };
```

NOTE: `nixpkgs.config.allowUnfree` is now set inside `modules/common/nix.nix` (Task 1), so it applies to both hosts.

- [ ] **Step 3: Verify the flake evaluates**

Run: `nix flake check 2>&1 | tail -20`
Expected: no evaluation errors for `nixosConfigurations.desktop`. (The `homelab` host does not exist yet — Step 3 may error on it; if so, that error is expected until Task 6. To check desktop alone, use the next step.)

- [ ] **Step 4: Build the renamed desktop host**

Run:
```bash
nixos-rebuild build --flake .#desktop
readlink -f result
```
Expected: build succeeds, producing a `nixos-system-*` store path.

- [ ] **Step 5: Diff against the baseline closure**

Run:
```bash
nix store diff-closures "$(cat /tmp/desktop-baseline.path)" "$(readlink -f result)"
```
Expected: empty or only trivial differences (e.g. nothing, or a path rename). There must be NO removed packages (no missing Hyprland/nvidia/pipewire/GUI apps) and NO unexpected additions. If real packages are added/removed, a module was misclassified — fix before continuing.

- [ ] **Step 6: Clean up and commit**

```bash
rm -f result
git add -A
git commit -m "refactor: flake mkHost helper, rename host nixos -> desktop"
```

- [ ] **Step 7: Grep for stale `#nixos` references**

Run: `grep -rn 'flake .#nixos\|\.#nixos' home/ hosts/ modules/ 2>/dev/null; grep -rn 'nixos-rebuild' home/ 2>/dev/null`
Expected: list any scripts/aliases that rebuild with `.#nixos`. If found (e.g. a HM shell alias), update them to `.#desktop` in the same commit. If none, note "no stale references."

---

### Task 6: Add `hosts/homelab/` with a placeholder hardware stub

**Files:**
- Create: `hosts/homelab/default.nix`
- Create: `hosts/homelab/hardware-configuration.nix` (placeholder; replaced in Task 7)

This lets `nixos-rebuild build --flake .#homelab` evaluate on the desktop before the laptop exists, proving the server config is correct and GUI-free.

- [ ] **Step 1: Write a placeholder `hosts/homelab/hardware-configuration.nix`**

Minimal stub so the config evaluates and builds. REPLACED in Task 7 by the laptop's real generated file.

```nix
# PLACEHOLDER — replaced by the laptop's `nixos-generate-config` output in Task 7.
{lib, modulesPath, ...}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "usbhid" "sd_mod"];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
```

- [ ] **Step 2: Write `hosts/homelab/default.nix`**

```nix
{...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/common
  ];

  system.stateVersion = "26.05";

  networking = {
    hostName = "homelab";
    # Old laptop almost certainly uses wifi; NetworkManager is the simplest
    # path. If it is wired-only, this can be dropped for plain networking.
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
    # Tailscale's UDP port for direct connections.
    allowedUDPPorts = [41641];
    checkReversePath = "loose";
  };

  # Allow remote `nixos-rebuild --target-host` to write to the store.
  nix.settings.trusted-users = ["root" "duartesj"];

  home-manager.users.duartesj = import ../../home/profiles/server.nix;
}
```

- [ ] **Step 3: Build the homelab host**

Run:
```bash
nixos-rebuild build --flake .#homelab
readlink -f result
```
Expected: build succeeds.

- [ ] **Step 4: Assert the server closure is GUI-free**

Run:
```bash
nix path-info -rh "$(readlink -f result)" | grep -Ei 'hyprland|waybar|spicetify|nvidia|pipewire|mesa|texlive' || echo "CLEAN: no desktop closures"
```
Expected: `CLEAN: no desktop closures` (or only an unavoidable transitive `mesa` from the kernel/firmware — investigate if Hyprland/waybar/spicetify/texlive appear, that means `home/profiles/server.nix` is pulling GUI modules).

- [ ] **Step 5: Clean up and commit**

```bash
rm -f result
git add hosts/homelab
git commit -m "feat: add homelab server host (placeholder hardware)"
```

---

### Task 7: Laptop clean install + remote deploy (physical hardware runbook)

**Files:**
- Replace: `hosts/homelab/hardware-configuration.nix` (placeholder -> real)

This task runs against the physical laptop. It is a runbook, not a `build`. Prerequisite: Tasks 1-6 committed and `nixos-rebuild build --flake .#homelab` green.

- [ ] **Step 1: Boot the NixOS minimal ISO on the laptop**

Flash the NixOS minimal x86_64 ISO to USB (`dd` or `cp` from the iso to the device), boot the laptop from it.

- [ ] **Step 2: Partition (UEFI) and format**

Identify the disk with `lsblk`. For a UEFI machine (replace `/dev/sdX`):
```bash
sudo parted /dev/sdX -- mklabel gpt
sudo parted /dev/sdX -- mkpart ESP fat32 1MiB 512MiB
sudo parted /dev/sdX -- set 1 esp on
sudo parted /dev/sdX -- mkpart primary 512MiB 100%
sudo mkfs.fat -F32 -n boot /dev/sdX1
sudo mkfs.ext4 -L nixos /dev/sdX2
```
(Labels `boot` and `nixos` match the placeholder hardware stub.)

- [ ] **Step 3: Mount and generate hardware config**

```bash
sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/boot /mnt/boot
sudo nixos-generate-config --root /mnt
```

- [ ] **Step 4: Minimal bootstrap install**

Edit `/mnt/etc/nixos/configuration.nix` to enable sshd + a temporary user password so the machine is reachable, then install. Minimal additions inside the config:
```nix
  services.openssh.enable = true;
  users.users.duartesj = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    initialPassword = "changeme";
  };
  networking.hostName = "homelab";
  # wifi: either nmcli after boot, or set networking.networkmanager.enable = true;
  networking.networkmanager.enable = true;
```
Then:
```bash
sudo nixos-install
sudo reboot
```

- [ ] **Step 5: Bring the laptop onto the network and find its IP**

Boot it, log in locally, connect wifi (`nmtui` or `nmcli device wifi connect <ssid> password <pw>`), note its LAN IP (`ip a`). Add a host alias on the desktop (temporary, by IP) or use the IP directly.

- [ ] **Step 6: Copy the real hardware config back to the repo**

From the desktop:
```bash
scp duartesj@<laptop-ip>:/etc/nixos/hardware-configuration.nix hosts/homelab/hardware-configuration.nix
```
Review the diff vs the placeholder; fix `hosts/homelab/default.nix` if boot mode is BIOS (use `boot.loader.grub` instead of systemd-boot) or if filesystem labels differ.

- [ ] **Step 7: Rebuild the homelab host locally to confirm the real hardware config evaluates**

Run:
```bash
nixos-rebuild build --flake .#homelab
nix path-info -rh "$(readlink -f result)" | grep -Ei 'hyprland|waybar|spicetify' || echo "CLEAN"
rm -f result
```
Expected: build succeeds, `CLEAN`.

- [ ] **Step 8: First remote deploy from the desktop**

Ensure the desktop's SSH key is authorized (it is, via `modules/common/users.nix`). Build on the fast desktop, activate on the laptop:
```bash
nixos-rebuild switch \
  --flake .#homelab \
  --target-host duartesj@<laptop-ip> \
  --build-host localhost \
  --use-remote-sudo
```
Expected: activation succeeds; sshd now key-only, password auth disabled.

- [ ] **Step 9: Join the tailnet on the laptop**

SSH into the laptop and run:
```bash
sudo tailscale up
```
Authenticate via the printed URL. Confirm `tailscale ip -4` returns an address.

- [ ] **Step 10: Verify all success criteria**

- [ ] SSH key-only from desktop over LAN: `ssh duartesj@<laptop-ip> true`
- [ ] SSH over Tailscale: `ssh duartesj@<tailscale-name> true`
- [ ] Password auth refused: `ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no duartesj@<laptop-ip>` -> permission denied.
- [ ] Lid-closed: close the lid, confirm SSH still responds.
- [ ] Second remote rebuild applies a trivial change (e.g. add a comment) with no password prompt.

- [ ] **Step 11: Commit the real hardware config**

```bash
git add hosts/homelab/hardware-configuration.nix hosts/homelab/default.nix
git commit -m "feat: real homelab hardware config + finalize host"
```

---

## Final Verification Checklist

- [ ] `nixos-rebuild build --flake .#desktop` succeeds; `nix store diff-closures` vs baseline shows no real package changes.
- [ ] `nixos-rebuild build --flake .#homelab` succeeds; closure is GUI-free.
- [ ] Desktop still rebuilds and runs Hyprland after `nixos-rebuild switch --flake .#desktop`.
- [ ] `homelab` reachable by SSH (key-only) on LAN and Tailscale; password + root login refused.
- [ ] Laptop runs lid-closed.
- [ ] Remote `nixos-rebuild --target-host` works without a password prompt.
