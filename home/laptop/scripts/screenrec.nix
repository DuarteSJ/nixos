{
  config,
  pkgs,
  ...
}: {
  home.packages = [
    (pkgs.writeShellApplication {
      name = "screenrec";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.procps
        pkgs.slurp
        pkgs.wf-recorder
        pkgs.pulseaudio
        pkgs.quickshell
      ];
      text = ''
        VIDEOS_DIR="$HOME/Videos/screenrec"

        # Drive the bar's REC chip.  Best effort: the shell may not be
        # running, and recording must never hang on it.  (A restarted shell
        # asks pgrep whether wf-recorder is running; no state file.)
        bar_rec() {
          timeout 2 qs -c shell ipc call rec "$1" >/dev/null 2>&1 || true
        }

        mkdir -p "$VIDEOS_DIR"

        # If wf-recorder is already running, stop it.  The run that started
        # it is waiting on it and clears the chip; do it here too in case
        # that one is gone.
        if pgrep -x wf-recorder >/dev/null; then
          pkill -x wf-recorder
          bar_rec stop
          exit 0
        fi

        # Select region
        geometry=$(slurp -d \
          -b "${config.colorScheme.palette.base00}66" \
          -c "${config.colorScheme.palette.base0E}ff" \
          -s "${config.colorScheme.palette.base0D}40" \
          -w 3 \
          -B "${config.colorScheme.palette.base01}99" \
        ) || {
          exit 1
        }

        sleep 0.1

        outfile="$VIDEOS_DIR/rec_$(date +%F_%H-%M-%S).mp4"

        # Only request system audio when a default sink actually exists; an
        # empty "--audio=.monitor" arg makes wf-recorder die immediately.
        sink="$(pactl get-default-sink 2>/dev/null || true)"
        audio_args=()
        if [[ -n "$sink" ]]; then
          audio_args+=("--audio=$sink.monitor")
        fi

        # Start recording (video + PipeWire system audio) in the background.
        wf-recorder \
          "''${audio_args[@]}" \
          -g "$geometry" \
          -f "$outfile" &
        pid=$!

        # However this ends -- toggled off, wf-recorder crashing or its
        # output going away, a failed start -- clear the REC chip.  If this
        # script is killed, stop the recorder too (SIGTERM, like the toggle;
        # wf-recorder finalizes the file) rather than leave it running unseen.
        trap 'bar_rec stop' EXIT
        trap 'kill -TERM "$pid" 2>/dev/null || true' INT TERM HUP

        # Give wf-recorder a moment to fail before lighting the chip (a
        # backgrounded failure can't be caught by errexit).
        sleep 0.2
        if ! kill -0 "$pid" 2>/dev/null; then
          echo "screenrec: wf-recorder failed to start" >&2
          exit 1
        fi
        bar_rec start

        # Stay until the recorder exits (wait returns early on a trapped
        # signal, hence the loop).
        while kill -0 "$pid" 2>/dev/null; do
          wait "$pid" || true
        done
      '';
    })
  ];
}
