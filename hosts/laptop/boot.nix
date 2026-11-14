_: {
  # Dual boot: Windows keeps the RTC in local time, so reading it as UTC put
  # the clock 1-2 h off after every Windows session until NTP caught up.
  time.hardwareClockInLocalTime = true;

  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
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
}
