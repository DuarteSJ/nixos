{ config, pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellScriptBin "alt-tab" ''
	# Get current workspace
	current_workspace=$(hyprctl activewindow | grep "workspace:" | awk '{print $2}' 2>/dev/null)

	# If we can't get current workspace from active window, try monitors
	if [ -z "$current_workspace" ]; then
	    current_workspace=$(hyprctl monitors | grep "active workspace:" | head -1 | awk '{print $3}')
	fi

	# Toggle between workspace 1 and 2
	if [ "$current_workspace" = "1" ]; then
	    hyprctl dispatch workspace 2
	else
	    hyprctl dispatch workspace 1
	fi
    '')
  ];
}

