{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellScriptBin "timer" ''
      # Ensure at least one argument is provided
      if [[ -z "$1" ]]; then
          ${pkgs.coreutils}/bin/echo "Usage: $0 [--title \"Custom Title\"] [--symbol \"⏳\"] [--silent] <time>"
          ${pkgs.coreutils}/bin/echo "Example: $0 --title \"Break\" --symbol \"🔥\" 5m 30s"
          exit 1
      fi
      # Default values
      minutes=0
      seconds=0
      notify_id=9234523  # Unique ID for persistent notification
      title="Timer"  # Default title (symbol will be added)
      symbol="⏳"  # Default symbol
      silent_mode=false  # By default, show live notifications
      # Parse arguments
      while [[ "$#" -gt 0 ]]; do
          case "$1" in
              --title)
                  if [[ -n "$2" ]]; then
                      title="$2"
                      shift 2
                  else
                      ${pkgs.coreutils}/bin/echo "Error: --title requires an argument."
                      exit 1
                  fi
                  ;;
              --symbol)
                  if [[ -n "$2" ]]; then
                      symbol="$2"
                      shift 2
                  else
                      ${pkgs.coreutils}/bin/echo "Error: --symbol requires an argument."
                      exit 1
                  fi
                  ;;
              --silent)
                  silent_mode=true
                  shift
                  ;;
              (*[0-9]m)
                  minutes="''${1%m}"
                  shift
                  ;;
              (*[0-9]s)
                  seconds="''${1%s}"
                  shift
                  ;;
              *)
                  ${pkgs.coreutils}/bin/echo "Invalid argument: $1"
                  ${pkgs.coreutils}/bin/echo "Usage: $0 [--title \"Custom Title\"] [--symbol \"⏳\"] [--silent] <time>"
                  exit 1
                  ;;
          esac
      done
      # Convert total time to seconds
      time_left=$(( minutes * 60 + seconds ))
      # Ensure at least some time was provided
      if (( time_left == 0 )); then
          ${pkgs.coreutils}/bin/echo "Error: You must specify at least minutes or seconds."
          exit 1
      fi
      # Apply the symbol to the title
      title="''${symbol} ''${title}"
      # Countdown loop
      while (( time_left > 0 )); do
          min=$(( time_left / 60 ))
          sec=$(( time_left % 60 ))
          if [[ "$silent_mode" = false ]]; then
              ${pkgs.dunst}/bin/dunstify -r $notify_id "$title" "Time remaining: ''${min}m ''${sec}s"
          fi
          ${pkgs.coreutils}/bin/sleep 1
          (( time_left-- ))
      done
      # Final notification
      ${pkgs.dunst}/bin/dunstify -u critical -r $notify_id "$title" " Time's up!"
    '')
  ];
}
