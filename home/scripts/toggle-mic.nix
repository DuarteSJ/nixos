{ config, pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellScriptBin "toggle-mic" ''
	#/run/current-system/sw/bin/bash

	# Get the current mute status of the microphone
	MUTE_STATUS=$(amixer get Capture | grep -oE '\[on\]|\[off\]' | head -n 1)

	# Toggle mute/unmute
	if [ "$MUTE_STATUS" = "[off]" ]; then
	    amixer set Capture cap
	    echo "Microphone unmuted."
	else
	    amixer set Capture nocap
	    echo "Microphone muted."
	fi
    '')
  ];
}

