{...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/common
    ../../modules/desktop
  ];

  system.stateVersion = "26.05";

  networking.hostName = "desktop";

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
