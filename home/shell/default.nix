# Desktop shell: bar + session menu (quickshell), launcher, notifications, cursor.
{...}: {
  imports = [
    ./quickshell
    ./rofi.nix
    ./dunst.nix
    ./cursor.nix
  ];
}
