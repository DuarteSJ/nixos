# `notify`: notify-send with dunstify-style `-r KEY` replacement.
#
# dunst let callers pick any replace id (`dunstify -r 7777 ...`), but per the
# notification spec the *server* owns ids: Quickshell ignores an id it never
# handed out and opens a new popup every time.  This wrapper keeps the old
# calling convention by remembering, per KEY, the id the server returned last
# time (notify-send -p) and replacing that one.  Everything else is passed
# straight to notify-send.
{
  writeShellApplication,
  libnotify,
  coreutils,
}:
writeShellApplication {
  name = "notify";
  runtimeInputs = [libnotify coreutils];
  text = ''
    args=()
    key=""
    while (( $# )); do
      case "$1" in
        -r|--replace) key="$2"; shift 2 ;;
        *) args+=("$1"); shift ;;
      esac
    done

    if [[ -z "$key" ]]; then
      exec notify-send "''${args[@]}"
    fi

    dir="''${XDG_RUNTIME_DIR:-/tmp}/notify-ids"
    mkdir -p "$dir"
    slot="$dir/$key"
    prev="$(cat "$slot" 2>/dev/null || true)"

    if [[ "$prev" =~ ^[0-9]+$ ]]; then
      id="$(notify-send -p -r "$prev" "''${args[@]}")"
    else
      id="$(notify-send -p "''${args[@]}")"
    fi
    printf '%s' "$id" > "$slot"
  '';
}
