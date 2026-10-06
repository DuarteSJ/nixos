import unittest

from bonk_reroll.game import MapState, NotReady
from bonk_reroll.memory import ReadError
from bonk_reroll.scanner import Scanner, Stop

PERFECT = ("perfect", {"microwaves": 2, "boss_curses": 2, "shady_moais": 9})
GOOD = ("good", {"microwaves": 2, "boss_curses": 2, "shady_moais": 8})

BAD_MAP = {"Microwaves": 1, "Boss Curses": 2, "Moais": 4, "Shady Guy": 4}
EIGHT_MAP = {"Microwaves": 2, "Boss Curses": 2, "Moais": 4, "Shady Guy": 4}
NINE_MAP = {"Microwaves": 2, "Boss Curses": 3, "Moais": 5, "Shady Guy": 4}


class FakeGame:
    """Each reset() generates the next map: 2 polls 'generating', then ready."""

    def __init__(self, maps):
        self.maps = list(maps)
        self.labels = {}
        self.seed = 1
        self.rev = 1
        self.generating_polls = 0

    def reset(self):
        self.labels = self.maps.pop(0)
        self.seed += 1
        self.rev += 1
        self.generating_polls = 2

    def map_state(self):
        if self.generating_polls:
            self.generating_polls -= 1
            return MapState(True, False, self.seed - 1, 0xA, 0xB)
        return MapState(False, False, self.seed, 0xA, 0xB)

    def feature_counts(self):
        return dict(self.labels), (self.rev,)


class StuckGame(FakeGame):
    def reset(self):
        pass  # nothing ever changes


class FlickerGame(FakeGame):
    """The first read after a reset sees a half-built dictionary."""

    def reset(self):
        super().reset()
        self.reads_after_reset = 0

    def feature_counts(self):
        labels, rev = super().feature_counts()
        if hasattr(self, "reads_after_reset"):
            self.reads_after_reset += 1
            if self.reads_after_reset == 1:
                return {}, rev
        return labels, rev


class SameRevisionGame(FakeGame):
    """New seed, but the dictionary is never rebuilt."""

    def reset(self):
        super().reset()
        self.rev -= 1


class FlakyGame(FakeGame):
    """Two torn reads right after each reset."""

    failures = 0

    def reset(self):
        super().reset()
        self.failures = 2

    def map_state(self):
        if self.failures:
            self.failures -= 1
            raise ReadError("torn read")
        return super().map_state()


class ColdGame(FakeGame):
    """Map state unreadable until the first reset (toggled during a load)."""

    def map_state(self):
        if not self.labels:
            raise NotReady("cold")
        return super().map_state()


class FakeClock:
    def __init__(self):
        self.now = 0.0

    def time(self):
        return self.now

    def sleep(self, seconds):
        self.now += seconds


def make(game, *, focused=lambda: True, cancelled=lambda: False, mode=lambda: PERFECT, on_reset=None):
    events = []

    def reset():
        events.append("reset")
        game.reset()
        if on_reset:
            on_reset()

    clock = FakeClock()
    scanner = Scanner(
        game,
        reset=reset,
        pause=lambda: events.append("pause"),
        focused=focused,
        notify=lambda title, body: events.append(("notify", title, body)),
        current_mode=mode,
        cancelled=cancelled,
        sleep=clock.sleep,
        clock=clock.time,
    )
    return scanner, events


class ScannerTests(unittest.TestCase):
    def test_rerolls_until_match_then_pauses(self):
        scanner, events = make(FakeGame([BAD_MAP, EIGHT_MAP, NINE_MAP]))
        scanner.run()
        self.assertEqual(events.count("reset"), 3)
        self.assertEqual(events[-2], "pause")
        self.assertEqual(events[-1][1], "perfect map after 3 rerolls")

    def test_progress_notification_per_miss(self):
        scanner, events = make(FakeGame([BAD_MAP, NINE_MAP]))
        scanner.run()
        self.assertIn(("notify", "Reroll #1 · perfect",
                       "microwaves 1/2 · boss_curses 2/2 · shady_moais 8/9"), events)

    def test_mode_switch_applies_to_next_evaluation(self):
        modes = [PERFECT]
        scanner, events = make(FakeGame([EIGHT_MAP]), mode=lambda: modes[0],
                               on_reset=lambda: modes.__setitem__(0, GOOD))
        scanner.run()
        self.assertEqual(events[-1][1], "good map after 1 rerolls")

    def test_lost_focus_stops_before_resetting(self):
        scanner, events = make(FakeGame([NINE_MAP]), focused=lambda: False)
        with self.assertRaisesRegex(Stop, "lost focus"):
            scanner.run()
        self.assertNotIn("reset", events)

    def test_cancel_stops(self):
        scanner, events = make(FakeGame([NINE_MAP]), cancelled=lambda: True)
        with self.assertRaisesRegex(Stop, "cancelled"):
            scanner.run()
        self.assertNotIn("reset", events)

    def test_no_pause_when_unfocused_at_match(self):
        calls = iter([True, False])  # focused before reset, not after match
        scanner, events = make(FakeGame([NINE_MAP]), focused=lambda: next(calls))
        scanner.run()
        self.assertNotIn("pause", events)
        self.assertEqual(events[-1][1], "perfect map after 1 rerolls")

    def test_times_out_when_map_never_changes(self):
        scanner, _ = make(StuckGame([]))
        with self.assertRaisesRegex(Stop, "not ready within 10 s"):
            scanner.run()

    def test_waits_for_identical_snapshots(self):
        scanner, events = make(FlickerGame([NINE_MAP]))
        scanner.run()
        self.assertEqual(events.count("reset"), 1)
        self.assertEqual(events[-1][1], "perfect map after 1 rerolls")

    def test_unchanged_dictionary_times_out(self):
        scanner, _ = make(SameRevisionGame([NINE_MAP]))
        with self.assertRaisesRegex(Stop, "not ready within 10 s"):
            scanner.run()

    def test_survives_transient_read_errors(self):
        scanner, events = make(FlakyGame([NINE_MAP]))
        scanner.run()
        self.assertEqual(events[-1][1], "perfect map after 1 rerolls")

    def test_unreadable_before_first_reset(self):
        scanner, events = make(ColdGame([NINE_MAP]))
        scanner.run()
        self.assertEqual(events[-1][1], "perfect map after 1 rerolls")

    def test_cancel_during_wait_stops(self):
        flag = []
        scanner, events = make(FakeGame([NINE_MAP]), cancelled=lambda: bool(flag),
                               on_reset=lambda: flag.append(1))
        with self.assertRaisesRegex(Stop, "cancelled"):
            scanner.run()
        self.assertEqual(events.count("reset"), 1)
        self.assertNotIn("pause", events)
