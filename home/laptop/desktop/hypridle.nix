{pkgs, ...}: {
  # Lock before every suspend (lid, session menu, `systemctl suspend`):
  # hypridle holds logind's sleep inhibitor and, with inhibit_sleep = 3,
  # releases it only once the session is actually locked.  The lock screen
  # is the quickshell shell's own (home/laptop/shell/quickshell, LockScreen.qml).
  services.hypridle = {
    enable = true;
    settings.general = {
      lock_cmd = "${pkgs.quickshell}/bin/qs -c shell ipc call lock lock";
      before_sleep_cmd = "loginctl lock-session";
      inhibit_sleep = 3;
    };
  };
}
