import os
import signal
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from pathlib import Path
from unittest import mock

from bonk_reroll.__main__ import Daemon, child_env, exit_code, forward_signals, run, send, serve


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


def start_serving(daemon, child, result):
    # Daemon thread: if a test fails before the fake child "exits", serve()
    # would loop forever and a non-daemon thread would hang the whole run
    # (and the Nix build's installCheckPhase).
    thread = threading.Thread(target=lambda: result.setdefault("rc", serve(daemon, child)), daemon=True)
    thread.start()
    return thread


def finish(thread, seconds=5):
    thread.join(seconds)
    if thread.is_alive():
        raise AssertionError("serve() did not return")


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
        thread = start_serving(daemon, child, result)
        wait_for(self.sock.exists)
        self.assertEqual(send("toggle"), 0)
        self.assertEqual(send("next-mode"), 0)
        wait_for(lambda: len(daemon.commands) == 2)
        child.code = 3
        finish(thread)
        self.assertEqual(daemon.commands, ["toggle", "next-mode"])
        self.assertTrue(daemon.stopped)
        self.assertFalse(self.sock.exists())
        self.assertEqual(result["rc"], 3)

    def test_daemon_errors_do_not_stop_serving(self):
        daemon, child, result = RaisingDaemon(), FakeChild(), {}
        with mock.patch("bonk_reroll.system.notify") as notify:
            thread = start_serving(daemon, child, result)
            wait_for(self.sock.exists)
            send("toggle")
            send("next-mode")
            wait_for(lambda: len(daemon.commands) == 2)
            child.code = 0
            finish(thread)
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


class ForwardSignals(unittest.TestCase):
    def test_relayed_to_child_and_restored(self):
        before = signal.getsignal(signal.SIGTERM)
        child = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(30)"])
        try:
            restore = forward_signals(child)
            try:
                # Call the installed handler instead of signalling ourselves:
                # a missing relay must fail the test, not kill the runner.
                signal.getsignal(signal.SIGTERM)(signal.SIGTERM, None)
                self.assertEqual(child.wait(5), -signal.SIGTERM)
            finally:
                restore()
        finally:
            child.kill()
            child.wait()
        self.assertIs(signal.getsignal(signal.SIGTERM), before)


class DaemonTestCase(unittest.TestCase):
    CONFIG = {
        "modes": [{"name": "perfect", "min": {"shady_moais": 9}}],
        "reset_key": "KEY_Q",
        "pause_key": "KEY_ESC",
    }

    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        for patcher in (mock.patch("bonk_reroll.system.VirtualKeyboard"),
                        mock.patch("bonk_reroll.system.state_file", return_value=Path(tmp.name) / "mode"),
                        mock.patch("bonk_reroll.system.notify")):
            patcher.start()
            self.addCleanup(patcher.stop)

    def daemon(self, config=None):
        daemon = Daemon(config or self.CONFIG)
        self.addCleanup(daemon.stop)
        return daemon


class DaemonValidation(DaemonTestCase):
    def test_unknown_counter_is_rejected(self):
        config = dict(self.CONFIG, modes=[{"name": "typo", "min": {"shady_moai": 9}}])
        with self.assertRaisesRegex(ValueError, "shady_moai"):
            Daemon(config)


class DaemonToggle(DaemonTestCase):
    """A worker that runs until cancelled, then lingers until `release`."""

    def setUp(self):
        super().setUp()
        self.scans = []
        self.release = threading.Event()
        self.addCleanup(self.release.set)

    def daemon(self, config=None):
        daemon = super().daemon(config)

        def scan(cancel):
            self.scans.append(cancel)
            cancel.wait(5)
            self.release.wait(5)

        daemon._scan = scan
        return daemon

    def test_restart_while_stopping_is_queued(self):
        daemon = self.daemon()
        daemon.toggle()
        wait_for(lambda: len(self.scans) == 1)
        daemon.toggle()  # stop
        self.assertTrue(self.scans[0].is_set())
        daemon.toggle()  # start again while the first worker still winds down
        self.assertEqual(len(self.scans), 1)
        self.release.set()
        wait_for(lambda: len(self.scans) == 2)
        self.assertFalse(self.scans[1].is_set())
        self.assertTrue(daemon.worker.is_alive())

    def test_second_toggle_unqueues_restart(self):
        daemon = self.daemon()
        daemon.toggle()
        wait_for(lambda: len(self.scans) == 1)
        daemon.toggle()  # stop
        daemon.toggle()  # queue a restart
        daemon.toggle()  # ...and take it back
        worker = daemon.worker
        self.release.set()
        worker.join(5)
        self.assertFalse(worker.is_alive())
        self.assertEqual(len(self.scans), 1)
        self.assertIs(daemon.worker, worker)

    def test_shutdown_drops_queued_restart(self):
        daemon = self.daemon()
        daemon.toggle()
        wait_for(lambda: len(self.scans) == 1)
        daemon.toggle()  # stop
        daemon.toggle()  # queue a restart
        worker = daemon.worker
        threading.Timer(0.1, self.release.set).start()
        daemon.stop()
        worker.join(5)
        self.assertEqual(len(self.scans), 1)


class DaemonKeysFree(DaemonTestCase):
    def test_waits_out_quiet_period_after_hotkey(self):
        daemon = self.daemon()
        with mock.patch("bonk_reroll.__main__.HOTKEY_QUIET", 0.2):
            daemon.handle("noop")  # any hotkey means Super may still be down
            start = time.monotonic()
            daemon.wait_keys_free(threading.Event())
            self.assertGreaterEqual(time.monotonic() - start, 0.15)

    def test_returns_at_once_without_recent_hotkey(self):
        daemon = self.daemon()
        start = time.monotonic()
        daemon.wait_keys_free(threading.Event())
        self.assertLess(time.monotonic() - start, 0.05)

    def test_cancel_ends_the_wait(self):
        daemon = self.daemon()
        cancel = threading.Event()
        cancel.set()
        with mock.patch("bonk_reroll.__main__.HOTKEY_QUIET", 5):
            daemon.handle("noop")
            start = time.monotonic()
            daemon.wait_keys_free(cancel)
        self.assertLess(time.monotonic() - start, 0.5)
