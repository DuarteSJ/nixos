import os
import sys
import tempfile
import threading
import time
import unittest
from pathlib import Path
from unittest import mock

from bonk_reroll.__main__ import Daemon, child_env, exit_code, run, send, serve


class ChildEnv(unittest.TestCase):
    def test_restores_stashed_and_drops_markers(self):
        env = {"PATH": "/bin", "BONK_REROLL_ORIG_LD_PRELOAD": "overlay.so",
               "BONK_REROLL_ORIG_LD_LIBRARY_PATH": ""}
        with mock.patch.dict(os.environ, env, clear=True):
            self.assertEqual(child_env(), {"PATH": "/bin", "LD_PRELOAD": "overlay.so", "LD_LIBRARY_PATH": ""})

    def test_absent_stays_absent(self):
        with mock.patch.dict(os.environ, {"PATH": "/bin"}, clear=True):
            self.assertEqual(child_env(), {"PATH": "/bin"})


class RecordingDaemon:
    def __init__(self):
        self.commands = []
        self.stopped = False

    def handle(self, command):
        self.commands.append(command)

    def stop(self):
        self.stopped = True


class RaisingDaemon(RecordingDaemon):
    def handle(self, command):
        super().handle(command)
        raise OSError("read-only state dir")


class FakeChild:
    code = None

    def poll(self):
        return self.code

    @property
    def returncode(self):
        return self.code


def wait_for(predicate, seconds=5):
    deadline = time.monotonic() + seconds
    while not predicate():
        if time.monotonic() > deadline:
            raise AssertionError("timed out")
        time.sleep(0.01)


class Socket(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        patcher = mock.patch.dict(os.environ, {"XDG_RUNTIME_DIR": self.tmp.name})
        patcher.start()
        self.addCleanup(patcher.stop)
        self.sock = Path(self.tmp.name) / "bonk-reroll.sock"

    def test_commands_reach_daemon_and_socket_is_removed(self):
        daemon, child, result = RecordingDaemon(), FakeChild(), {}
        thread = threading.Thread(target=lambda: result.setdefault("rc", serve(daemon, child)))
        thread.start()
        wait_for(self.sock.exists)
        self.assertEqual(send("toggle"), 0)
        self.assertEqual(send("next-mode"), 0)
        wait_for(lambda: len(daemon.commands) == 2)
        child.code = 3
        thread.join(5)
        self.assertEqual(daemon.commands, ["toggle", "next-mode"])
        self.assertTrue(daemon.stopped)
        self.assertFalse(self.sock.exists())
        self.assertEqual(result["rc"], 3)

    def test_daemon_errors_do_not_stop_serving(self):
        daemon, child, result = RaisingDaemon(), FakeChild(), {}
        with mock.patch("bonk_reroll.system.notify") as notify:
            thread = threading.Thread(target=lambda: result.setdefault("rc", serve(daemon, child)))
            thread.start()
            wait_for(self.sock.exists)
            send("toggle")
            send("next-mode")
            wait_for(lambda: len(daemon.commands) == 2)
            child.code = 0
            thread.join(5)
        self.assertEqual(result["rc"], 0)
        self.assertEqual(notify.call_count, 2)

    def test_send_without_daemon_notifies(self):
        with mock.patch("bonk_reroll.system.notify") as notify:
            self.assertEqual(send("toggle"), 1)
        notify.assert_called_once()


class Run(unittest.TestCase):
    GAME = [sys.executable, "-c", "import sys; sys.exit(5)"]

    def test_game_runs_when_daemon_cannot_start(self):
        with tempfile.TemporaryDirectory() as tmp:
            config = Path(tmp) / "c.json"
            config.write_text('{"modes": [], "reset_key": "KEY_Q", "pause_key": "KEY_ESC"}')
            with mock.patch("bonk_reroll.__main__.Daemon", side_effect=OSError("no uinput")), \
                    mock.patch("bonk_reroll.system.notify") as notify:
                self.assertEqual(run(str(config), self.GAME), 5)
        notify.assert_called_once()

    def test_game_runs_with_missing_config(self):
        with mock.patch("bonk_reroll.system.notify") as notify:
            self.assertEqual(run("/nonexistent/bonk-reroll.json", self.GAME), 5)
        notify.assert_called_once()

    def test_signal_exit_code(self):
        self.assertEqual(exit_code(-9), 137)
        self.assertEqual(exit_code(3), 3)


class DaemonModes(unittest.TestCase):
    CONFIG = {
        "modes": [{"name": "perfect", "min": {"shady_moais": 9}},
                  {"name": "good", "min": {"shady_moais": 8}}],
        "reset_key": "KEY_Q",
        "pause_key": "KEY_ESC",
    }

    def test_next_mode_wraps_and_persists(self):
        with tempfile.TemporaryDirectory() as tmp:
            state = Path(tmp) / "mode"
            with mock.patch("bonk_reroll.system.VirtualKeyboard"), \
                    mock.patch("bonk_reroll.system.state_file", return_value=state), \
                    mock.patch("bonk_reroll.system.notify"):
                daemon = Daemon(self.CONFIG)
                self.assertEqual(daemon.current_mode()[0], "perfect")
                daemon.next_mode()
                self.assertEqual(daemon.current_mode()[0], "good")
                self.assertEqual(state.read_text(), "good\n")
                self.assertEqual(Daemon(self.CONFIG).current_mode()[0], "good")
                daemon.next_mode()
                self.assertEqual(daemon.current_mode()[0], "perfect")
