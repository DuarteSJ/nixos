{
  pkgs,
  notifyPkg,
  ...
}: {
  home.packages = [
    (pkgs.writeShellApplication {
      name = "timer";
      runtimeInputs = [
        pkgs.coreutils
        notifyPkg
      ];
      text = ''
        usage() {
            echo "Usage: timer [--title T] [--symbol S] [--silent] <N>m|<N>s..."
            echo "Example: timer --title Break --symbol 🔥 5m 30s"
        }
        die() { echo "timer: $1" >&2; usage >&2; exit 1; }

        # Validate everything before starting, so bad input never runs a
        # partial timer.
        title="Timer"; symbol="⏳"; silent=false; total=0
        while (( $# )); do
            case "$1" in
                --title|--symbol)
                    (( $# >= 2 )) || die "$1 needs a value"
                    if [[ $1 == --title ]]; then title="$2"; else symbol="$2"; fi
                    shift 2;;
                --silent) silent=true; shift;;
                -h|--help) usage; exit 0;;
                *)
                    # 10#: leading zeros are decimal, not octal (010s = 10 s).
                    [[ $1 =~ ^([0-9]{1,6})([ms])$ ]] || die "invalid argument: $1"
                    n=$(( 10#''${BASH_REMATCH[1]} ))
                    [[ ''${BASH_REMATCH[2]} == m ]] && n=$(( n * 60 ))
                    total=$(( total + n ))
                    shift;;
            esac
        done
        (( total > 0 )) || die "no duration given"

        title="''${symbol} ''${title}"
        id=$$  # Unique per invocation so concurrent timers don't collide

        if $silent; then
            sleep "$total"
        else
            # Absolute deadline so we don't accumulate sleep/clock drift.
            printf -v now '%(%s)T' -1
            end=$(( now + total ))
            while (( (remaining = end - now) > 0 )); do
                # A missed tick (e.g. the shell restarting) must not kill the timer.
                notify -r "timer-$id" "$title" "Time remaining: $(( remaining / 60 ))m $(( remaining % 60 ))s" || true
                sleep 1
                printf -v now '%(%s)T' -1
            done
        fi

        # The one notification that matters: retry for a few seconds.
        for _ in 1 2 3 4 5; do
            notify -u critical -r "timer-$id" "$title" "Time's up!" && exit 0
            sleep 1
        done
        echo "timer: could not send the final notification" >&2
        exit 1
      '';
    })
  ];
}
