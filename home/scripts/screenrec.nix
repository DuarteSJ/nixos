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
      ];
      text = ''
        VIDEOS_DIR="$HOME/Videos/screenrec"
        RECORDING_FLAG="/tmp/screenrec-recording"

        mkdir -p "$VIDEOS_DIR"

        # If wf-recorder is already running, stop it
        if pgrep -x wf-recorder >/dev/null; then
          pkill -x wf-recorder
          rm -f "$RECORDING_FLAG"
          sleep 0.5
          pkill -RTMIN+8 waybar
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

        # Give wf-recorder a moment to fail before committing the flag that
        # drives the waybar REC indicator. A backgrounded failure can't be
        # caught by errexit, so check explicitly: only raise the flag if the
        # recorder is still alive, otherwise clean up so waybar isn't stuck
        # showing REC forever.
        sleep 0.2
        if kill -0 "$pid" 2>/dev/null; then
          touch "$RECORDING_FLAG"
          pkill -RTMIN+8 waybar
        else
          rm -f "$RECORDING_FLAG"
          echo "screenrec: wf-recorder failed to start" >&2
          exit 1
        fi
      '';
    })
  ];
}
