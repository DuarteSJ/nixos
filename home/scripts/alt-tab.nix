{
  config,
  pkgs,
  ...
}: {
  home.packages = [
    (pkgs.writeShellScriptBin "alt-tab" ''
      # Get current workspace
      current_workspace=$(${pkgs.hyprland}/bin/hyprctl activewindow | ${pkgs.gnugrep}/bin/grep "workspace:" | ${pkgs.gawk}/bin/awk '{print $2}' 2>/dev/null)
      # If we can't get current workspace from active window, try monitors
      if [ -z "$current_workspace" ]; then
          current_workspace=$(${pkgs.hyprland}/bin/hyprctl monitors | ${pkgs.gnugrep}/bin/grep "active workspace:" | ${pkgs.coreutils}/bin/head -1 | ${pkgs.gawk}/bin/awk '{print $3}')
      fi
      # Toggle between workspace 1 and 2
      if [ "$current_workspace" = "1" ]; then
          ${pkgs.hyprland}/bin/hyprctl dispatch workspace 2
      else
          ${pkgs.hyprland}/bin/hyprctl dispatch workspace 1
      fi
    '')
  ];
}
