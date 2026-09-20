# Desktop shell: bar, launcher, notifications, cursor.
{...}: {
  imports = [
    ./waybar.nix
    ./rofi.nix
    ./dunst.nix
    ./cursor.nix
  ];
}
