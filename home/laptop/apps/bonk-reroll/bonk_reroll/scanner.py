"""The reroll loop. All I/O is injected so it can be tested with fakes."""
import time

from .game import NotReady
from .memory import ReadError
from .rules import counters_from_labels, describe, matches


class Stop(Exception):
    """Rerolling ended without a match; the message says why."""


class Scanner:
    """`keys_free` blocks until a virtual key press is safe (no hotkey modifier
    may still be held); it may return early once cancelled, re-checked after.

    `settle`: a new map's counters must read identically this far apart.  It
    spans several frames even at low frame rates (100 ms = one 10 fps frame),
    so two reads inside one frame of a dictionary still being filled can't
    pass as stable; it costs ~0.1 s on a reset that holds Q for ~1 s.
    """

    def __init__(self, game, *, reset, pause, focused, notify, current_mode, cancelled,
                 keys_free=lambda: None, sleep=time.sleep, clock=time.monotonic,
                 timeout=10.0, poll=0.01, settle=0.1):
        self.game = game
        self.reset = reset
        self.pause = pause
        self.focused = focused
        self.notify = notify
        self.current_mode = current_mode
        self.cancelled = cancelled
        self.keys_free = keys_free
        self.sleep = sleep
        self.clock = clock
        self.timeout = timeout
        self.poll = poll
        self.settle = settle

    def run(self):
        """Reroll until a map matches the current mode; raise Stop otherwise."""
        rerolls = 0
        while True:
            before, before_rev = self._snapshot()
            self._ready_to_press()
            self.reset()
            rerolls += 1
            counts = counters_from_labels(self._wait_for_new_map(before, before_rev))
            name, minimums = self.current_mode()
            if matches(minimums, counts):
                self.keys_free()
                if not self.cancelled() and self.focused():
                    self.pause()
                self.notify(f"{name} map after {rerolls} rerolls", describe(minimums, counts))
                return
            self.notify(f"Reroll #{rerolls} · {name}", describe(minimums, counts))

    def _ready_to_press(self):
        """Gate before each reset press; raise Stop if it must not happen.

        Cancellation is checked once more right before the press: a stop
        hotkey landing during the focus query means Super is down right now,
        and Hyprland would merge a virtual Q into Mod+Q.
        """
        if self.cancelled():
            raise Stop("cancelled")
        self.keys_free()
        if self.cancelled():
            raise Stop("cancelled")
        if not self.focused():
            raise Stop("Megabonk lost focus")
        if self.cancelled():
            raise Stop("cancelled")

    def _snapshot(self):
        try:
            state = self.game.map_state()
        except (NotReady, ReadError):
            state = None
        try:
            _, rev = self.game.feature_counts()
        except (NotReady, ReadError):
            rev = None
        return state, rev

    def _wait_for_new_map(self, before, before_rev):
        """Labels of the next map once generated, new, and stable for `settle` s."""
        deadline = self.clock() + self.timeout
        seen_generating = False
        candidate = None
        while self.clock() < deadline:
            if self.cancelled():
                raise Stop("cancelled")
            try:
                state = self.game.map_state()
                seen_generating = seen_generating or state.generating
                changed = seen_generating or before is None or state.identity != before.identity
                if state.ready and changed:
                    snapshot = self.game.feature_counts()
                    if snapshot[1] != before_rev:
                        if snapshot == candidate:
                            return snapshot[0]
                        candidate = snapshot
                        self.sleep(self.settle)
                        continue
                candidate = None
            except (NotReady, ReadError):
                candidate = None
            self.sleep(self.poll)
        raise Stop(f"new map not ready within {self.timeout:g} s")
