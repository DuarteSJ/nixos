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
            echo "Usage: $0 [--title T] [--symbol S] [--silent] <time...>"
            echo "Example: $0 --title Break --symbol 🔥 5m 30s"
        }

        title="Timer"; symbol="⏳"; silent=false; total=0
        while (( $# )); do
            case "$1" in
                --title)  title="$2";  shift 2;;
                --symbol) symbol="$2"; shift 2;;
                --silent) silent=true; shift;;
                *[0-9]m)  total=$(( total + ''${1%m} * 60 )); shift;;
                *[0-9]s)  total=$(( total + ''${1%s} ));      shift;;
                *) echo "Invalid argument: $1"; usage; exit 1;;
            esac
        done
        (( total > 0 )) || { usage; exit 1; }

        title="''${symbol} ''${title}"
        id=$$  # Unique per invocation so concurrent timers don't collide

        # Absolute deadline so we don't accumulate sleep/clock drift.
        end=$(( $(date +%s) + total ))
        while (( (remaining = end - $(date +%s)) > 0 )); do
            $silent || dunstify -r "$id" "$title" "Time remaining: $(( remaining / 60 ))m $(( remaining % 60 ))s"
            sleep 1
        done
        dunstify -u critical -r "$id" "$title" "Time's up!"
      '';
    })
  ];
}
