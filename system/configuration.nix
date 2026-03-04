{
  pkgs,
  inputs,
  ...
}: {
  imports = [./hardware-configuration.nix];

  # System
  system.stateVersion = "25.11";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.nameservers = ["1.1.1.1" "8.8.8.8"];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Locale & time
  time.timeZone = "Europe/Lisbon";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_PT.UTF-8";
    LC_IDENTIFICATION = "pt_PT.UTF-8";
    LC_MEASUREMENT = "pt_PT.UTF-8";
    LC_MONETARY = "pt_PT.UTF-8";
    LC_NAME = "pt_PT.UTF-8";
    LC_NUMERIC = "pt_PT.UTF-8";
    LC_PAPER = "pt_PT.UTF-8";
    LC_TELEPHONE = "pt_PT.UTF-8";
    LC_TIME = "pt_PT.UTF-8";
  };

  # Users
  users.users.duartesj = {
    isNormalUser = true;
    description = "Duarte S. Jose";
    shell = pkgs.zsh;
    extraGroups = ["networkmanager" "wheel" "adbusers"];
  };

  # Display & desktop
  services = {
    displayManager.gdm.enable = true;
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };
  };
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Hardware
  hardware = {
    bluetooth.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia.modesetting.enable = true;
  };

  # Audio
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Programs
  programs = {
    zsh.enable = true;
    adb.enable = true;
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = true;
    };
    gamemode.enable = true;
  };

  # Services
  services.resolved.enable = true;
  services.printing.enable = true;

  # udev rules
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="vial:f64c2b3c", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
  '';
}
