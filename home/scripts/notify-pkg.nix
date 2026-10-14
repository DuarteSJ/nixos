# `notify`: notify-send with dunstify-style `-r KEY` replacement.
#
#   notify -r KEY [-t ms] [-u urgency] [-a app] TITLE BODY
#
# dunst let callers pick any replace id (`dunstify -r 7777 ...`), but per the
# notification spec the *server* owns ids.  So `-r KEY` becomes a stack tag
# (hint x-dunst-stack-tag): the shell (home/shell/quickshell, Notifications.qml)
# swaps the shown notification with the same tag for the new one, in place.
# No state is kept here.  Everything else goes straight to notify-send.
{
  writeShellApplication,
  libnotify,
}:
writeShellApplication {
  name = "notify";
  runtimeInputs = [libnotify];
  text = ''
    args=()
    while (( $# )); do
      case "$1" in
        -r|--replace)
          if (( $# < 2 )); then
            echo "notify: $1 needs a KEY" >&2
            exit 2
          fi
          args+=(-h "string:x-dunst-stack-tag:$2")
          shift 2
          ;;
        *) args+=("$1"); shift ;;
      esac
    done
    exec notify-send "''${args[@]}"
  '';
}
