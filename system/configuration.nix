{
  pkgs,
  lib,
  ...
}: {
  imports = [./hardware-configuration.nix];

  # System
  system.stateVersion = "26.05";
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

  # Boot
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
      # Hand-maintained Windows entry. useOSProber = false above means GRUB
      # does NOT auto-detect other OSes, so this menuentry is written by hand.
      # 7801-1D56 is the Windows ESP (its own FAT32 EFI System Partition),
      # which is distinct from /boot's NixOS ESP (73EE-BBCB, see
      # hardware-configuration.nix). If Windows is ever reinstalled or its ESP
      # repartitioned the UUID will change and this entry breaks silently.
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

  # Networking
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    nameservers = ["1.1.1.1" "8.8.8.8"];
  };

  environment.systemPackages = [pkgs.openvpn pkgs.android-tools];

  # Locale & time
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

  # Users
  users.users.duartesj = {
    isNormalUser = true;
    description = "Duarte S. Jose";
    shell = pkgs.zsh;
    extraGroups = ["networkmanager" "wheel"];
  };

  # NVIDIA driver selection. REQUIRED to activate the hardware.nvidia block
  # below: the nvidia module gates its entire config on
  # `hardware.nvidia.enabled`, which is `elem "nvidia" videoDrivers`. Needed
  # even on pure Wayland/Hyprland (no X server is started by setting this).
  services.xserver.videoDrivers = ["nvidia"];

  # Hardware
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
          enableOffloadCmd = true; # nvidia-offload helper command
        };
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };

  # Programs
  programs = {
    zsh.enable = true;
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
  };

  # Services
  services = {
    # TODO: add a display manager
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

  # Environment
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
  };

  # Security
  security.rtkit.enable = true;
}
