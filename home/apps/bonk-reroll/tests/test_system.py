import json
import subprocess
import sys
import tempfile
import types
import unittest
from pathlib import Path
from unittest import mock

from bonk_reroll import system


class ResetHold(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.path = Path(self.tmp.name) / "config.json"

    def test_nested_value_plus_margin(self):
        self.path.write_text(json.dumps({"cfGameSettings": {"quick_reset_time": 0.5}}))
        self.assertAlmostEqual(system.reset_hold_seconds(self.path), 0.55)

    def test_missing_file_uses_default(self):
        self.assertAlmostEqual(system.reset_hold_seconds(self.path), 1.05)

    def test_garbage_uses_default(self):
        self.path.write_text("{not json")
        self.assertAlmostEqual(system.reset_hold_seconds(self.path), 1.05)

    def test_floor(self):
        self.path.write_text(json.dumps({"quick_reset_time": 0}))
        self.assertAlmostEqual(system.reset_hold_seconds(self.path), 0.06)

    def test_non_finite_uses_default(self):
        self.path.write_text('{"quick_reset_time": NaN}')
        self.assertAlmostEqual(system.reset_hold_seconds(self.path), 1.05)


class ModeState(unittest.TestCase):
    def test_round_trip(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "bonk-reroll" / "mode"
            system.save_mode("good", path)
            self.assertEqual(system.load_mode_index(["perfect", "good"], path), 1)

    def test_missing_or_unknown_is_first(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "mode"
            self.assertEqual(system.load_mode_index(["perfect", "good"], path), 0)
            path.write_text("gone\n")
            self.assertEqual(system.load_mode_index(["perfect", "good"], path), 0)


def hyprctl(stdout):
    return mock.patch("subprocess.run", return_value=subprocess.CompletedProcess([], 0, stdout, ""))


class Focus(unittest.TestCase):
    def test_pid_match(self):
        with hyprctl('{"pid": 42, "class": "Megabonk.x86_64"}'):
            self.assertTrue(system.game_focused(42))

    def test_other_window(self):
        with hyprctl('{"pid": 7, "class": "kitty"}'):
            self.assertFalse(system.game_focused(42))

    def test_no_window(self):
        with hyprctl("{}"):
            self.assertFalse(system.game_focused(42))

    def test_hyprctl_failure_is_unfocused(self):
        with mock.patch("subprocess.run", side_effect=FileNotFoundError):
            self.assertFalse(system.game_focused(42))

    def test_non_object_json_is_unfocused(self):
        with hyprctl("[]"):
            self.assertFalse(system.game_focused(42))


class FakeUInput:
    def __init__(self, capabilities, name):
        self.capabilities = capabilities
        self.name = name
        self.events = []

    def write(self, etype, code, value):
        self.events.append((etype, code, value))

    def syn(self):
        self.events.append("syn")


def fake_evdev():
    ecodes = types.SimpleNamespace(EV_KEY=1, ecodes={"KEY_Q": 16, "KEY_ESC": 1})
    return types.SimpleNamespace(UInput=FakeUInput, ecodes=ecodes)


class Keyboard(unittest.TestCase):
    def setUp(self):
        patcher = mock.patch.dict(sys.modules, {"evdev": fake_evdev()})
        patcher.start()
        self.addCleanup(patcher.stop)

    def test_hold_presses_then_releases(self):
        keyboard = system.VirtualKeyboard(["KEY_Q", "KEY_ESC"])
        with mock.patch("time.sleep") as sleep:
            keyboard.hold("KEY_Q", 1.05)
        sleep.assert_called_once_with(1.05)
        self.assertEqual(keyboard._ui.capabilities, {1: [16, 1]})
        self.assertEqual(keyboard._ui.events, [(1, 16, 1), "syn", (1, 16, 0), "syn"])

    def test_releases_even_if_interrupted(self):
        keyboard = system.VirtualKeyboard(["KEY_Q"])
        with mock.patch("time.sleep", side_effect=KeyboardInterrupt):
            with self.assertRaises(KeyboardInterrupt):
                keyboard.hold("KEY_Q", 1.05)
        self.assertEqual(keyboard._ui.events[-2:], [(1, 16, 0), "syn"])
