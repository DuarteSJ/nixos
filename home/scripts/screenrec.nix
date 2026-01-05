{ config, pkgs, ... }: {
  home.packages = [
    (pkgs.writeShellScriptBin "screenrec" ''
      set -euo pipefail
      
      VIDEOS_DIR="$HOME/Videos/screenrec"
      RECORDING_FLAG="/tmp/screenrec-recording"
      
      mkdir -p "$VIDEOS_DIR"
      
      # If wf-recorder is already running, stop it
      if ${pkgs.procps}/bin/pgrep -x wf-recorder >/dev/null; then
        ${pkgs.procps}/bin/pkill -x wf-recorder
        rm -f "$RECORDING_FLAG"
        ${pkgs.coreutils}/bin/sleep 0.5
        ${pkgs.procps}/bin/pkill -RTMIN+8 waybar
        exit 0
      fi
      
      # Select region
      geometry=$(${pkgs.slurp}/bin/slurp -d \
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
      
      # Create recording flag
      touch "$RECORDING_FLAG"
      
      # Start recording (video + PipeWire audio)
      ${pkgs.wf-recorder}/bin/wf-recorder \
        --audio \
        -g "$geometry" \
        -f "$outfile" &
      
      ${pkgs.coreutils}/bin/sleep 0.5
      ${pkgs.procps}/bin/pkill -RTMIN+8 waybar
    '')
  ];
}
