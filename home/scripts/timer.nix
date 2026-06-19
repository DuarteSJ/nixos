{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellApplication {
      name = "timer";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.dunst
      ];
      text = ''
        usage() {
            echo "Usage: $0 [--title \"Custom Title\"] [--symbol \"⏳\"] [--silent] <time>"
            echo "Example: $0 --title \"Break\" --symbol \"🔥\" 5m 30s"
        }
        # Ensure at least one argument is provided
        if [[ -z "''${1:-}" ]]; then
            usage
            exit 1
        fi
        # Default values
        minutes=0
        seconds=0
        notify_id=$$  # Unique per invocation so concurrent timers don't collide
        title="Timer"  # Default title (symbol will be added)
        symbol="⏳"  # Default symbol
        silent_mode=false  # By default, show live notifications
        # Parse arguments
        while [[ "$#" -gt 0 ]]; do
            case "$1" in
                --title)
                    if [[ -n "''${2:-}" ]]; then
                        title="$2"
                        shift 2
                    else
                        echo "Error: --title requires an argument."
                        exit 1
                    fi
                    ;;
                --symbol)
                    if [[ -n "''${2:-}" ]]; then
                        symbol="$2"
                        shift 2
                    else
                        echo "Error: --symbol requires an argument."
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
                    echo "Invalid argument: $1"
                    usage
                    exit 1
                    ;;
            esac
        done
        # Convert total time to seconds
        time_left=$(( minutes * 60 + seconds ))
        # Ensure at least some time was provided
        if (( time_left == 0 )); then
            echo "Error: You must specify at least minutes or seconds."
            exit 1
        fi
        # Apply the symbol to the title
        title="''${symbol} ''${title}"
        # Countdown loop, driven by an absolute wall-clock deadline so we don't
        # accumulate sleep/clock drift across long timers.
        end=$(( $(date +%s) + time_left ))
        while :; do
            remaining=$(( end - $(date +%s) ))
            (( remaining <= 0 )) && break
            min=$(( remaining / 60 ))
            sec=$(( remaining % 60 ))
            if [[ "$silent_mode" = false ]]; then
                dunstify -r "$notify_id" "$title" "Time remaining: ''${min}m ''${sec}s"
            fi
            sleep 1
        done
        # Final notification
        dunstify -u critical -r "$notify_id" "$title" " Time's up!"
      '';
    })
  ];
}
