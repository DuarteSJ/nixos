{
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [./hardware-configuration.nix];

  # System
  system.stateVersion = "25.11";
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    nameservers = ["1.1.1.1" "8.8.8.8"];
  };

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
    extraGroups = ["networkmanager" "wheel" "adbusers"];
  };

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
    adb.enable = true;
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
