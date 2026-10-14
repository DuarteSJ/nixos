{lib, ...}: {
  time.timeZone = "Europe/Lisbon";
  # Dual boot: Windows keeps the RTC in local time, so reading it as UTC put
  # the clock 1-2 h off after every Windows session until NTP caught up.
  time.hardwareClockInLocalTime = true;
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
