"""Side effects: virtual keyboard, Hyprland focus, notifications, files."""
import json
import math
import os
import subprocess
import time
from pathlib import Path

GAME_CONFIG = Path.home() / ".config/unity3d/Ved/Megabonk/Saves/LocalDir/config.json"
DEFAULT_RESET_TIME = 1.0
HOLD_MARGIN = 0.05
NOTIFY_ID = "7778"  # one notification slot, replaced in place


def _find_key(obj, key):
    if isinstance(obj, dict):
        if key in obj:
            return obj[key]
        children = obj.values()
    elif isinstance(obj, list):
        children = obj
    else:
        return None
    for child in children:
        found = _find_key(child, key)
        if found is not None:
            return found
    return None


def reset_hold_seconds(config_path=GAME_CONFIG):
    """How long to hold quick reset: the game's own threshold plus a margin."""
    try:
        seconds = float(_find_key(json.loads(Path(config_path).read_text()), "quick_reset_time"))
    except (OSError, ValueError, TypeError, OverflowError):
        seconds = DEFAULT_RESET_TIME
    if not math.isfinite(seconds):
        seconds = DEFAULT_RESET_TIME
    return max(seconds, 0.01) + HOLD_MARGIN


def state_file():
    base = os.environ.get("XDG_STATE_HOME") or str(Path.home() / ".local/state")
    return Path(base) / "bonk-reroll" / "mode"


def load_mode_index(names, path):
    try:
        return names.index(path.read_text().strip())
    except (OSError, ValueError):
        return 0


def save_mode(name, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(name + "\n")


def game_focused(pid):
    try:
        out = subprocess.run(["hyprctl", "activewindow", "-j"],
                             capture_output=True, text=True, timeout=2, check=True).stdout
        window = json.loads(out)
    except (OSError, subprocess.SubprocessError, ValueError):
        return False
    if not isinstance(window, dict):
        return False
    return window.get("pid") == pid or "megabonk" in str(window.get("class", "")).lower()


def notify(title, body=""):
    try:
        subprocess.run(["dunstify", "-a", "bonk-reroll", "-r", NOTIFY_ID, title, body],
                       capture_output=True, timeout=5, check=False)
    except (OSError, subprocess.SubprocessError):
        pass


class VirtualKeyboard:
    """A uinput keyboard that can press only `keys` (evdev names, e.g. KEY_Q)."""

    def __init__(self, keys):
        from evdev import UInput, ecodes  # lazy: tests don't need evdev

        self._ecodes = ecodes
        self._ui = UInput({ecodes.EV_KEY: [ecodes.ecodes[k] for k in keys]}, name="bonk-reroll")

    def hold(self, key, seconds):
        code = self._ecodes.ecodes[key]
        self._ui.write(self._ecodes.EV_KEY, code, 1)
        self._ui.syn()
        try:
            time.sleep(seconds)
        finally:  # never leave the key stuck down
            self._ui.write(self._ecodes.EV_KEY, code, 0)
            self._ui.syn()
