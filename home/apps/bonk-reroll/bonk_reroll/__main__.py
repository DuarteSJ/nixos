"""bonk-reroll: Megabonk map reroller.

  bonk-reroll --config FILE run CMD...   run CMD (the game) and serve hotkeys
  bonk-reroll toggle                      start/stop rerolling
  bonk-reroll next-mode                   cycle the active mode
  bonk-reroll probe                       print what it reads from the game
"""
import argparse
import json
import os
import signal
import socket
import subprocess
import sys
import threading
import time
from pathlib import Path

from . import rules, system
from .game import BUILD, Game, NotReady, OffsetsOutdated
from .memory import ProcessMemory, ReadError, find_pid, module_base
from .scanner import Scanner, Stop

CLIENT_COMMANDS = ("toggle", "next-mode")
# Steam sets these for the game. The wrapper stashes them under STASH_PREFIX
# and unsets them so our Nix Python runs clean; run() restores them for CMD.
STASHED = ("LD_LIBRARY_PATH", "LD_PRELOAD")
STASH_PREFIX = "BONK_REROLL_ORIG_"
# Hyprland merges modifiers across keyboards, so a virtual Q pressed while
# Super is still held from a Mod+F5 / Mod+Shift+F5 hotkey is Mod+Q (opens a
# terminal).  The physical keyboard state is unreadable here (that needs the
# `input` group, i.e. a keylogger), so every hotkey counts as "Super down" and
# no virtual key is pressed until this long after the last one.
HOTKEY_QUIET = 0.5
# Forwarded to the game: Steam stopping the game may signal only us, the top
# of the launch command, and dying alone would orphan the game.
FORWARDED_SIGNALS = (signal.SIGTERM, signal.SIGINT, signal.SIGHUP)


def socket_path():
    return Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "bonk-reroll.sock"


def child_env():
    env = dict(os.environ)
    for name in STASHED:
        original = env.pop(STASH_PREFIX + name, None)
        if original is not None:
            env[name] = original
    return env


def send(command):
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.connect(str(socket_path()))
            s.sendall(command.encode() + b"\n")
    except OSError:
        system.notify("bonk-reroll not running", "Launch Megabonk with the bonk-reroll launch option.")
        return 1
    return 0


class Daemon:
    def __init__(self, config):
        rules.validate(config["modes"])
        self.modes = config["modes"]
        self.reset_key = config["reset_key"]
        self.pause_key = config["pause_key"]
        self.state_path = system.state_file()
        self.mode_index = system.load_mode_index([m["name"] for m in self.modes], self.state_path)
        self.keyboard = system.VirtualKeyboard([self.reset_key, self.pause_key])
        self.lock = threading.Lock()
        self.cancel = threading.Event()
        self.worker = None
        self.restart_pending = False  # toggled on while a stopped worker winds down
        self.stopping = False
        self.last_hotkey = float("-inf")

    def current_mode(self):
        with self.lock:
            mode = self.modes[self.mode_index]
        return mode["name"], mode["min"]

    def handle(self, command):
        with self.lock:
            self.last_hotkey = time.monotonic()
        if command == "toggle":
            self.toggle()
        elif command == "next-mode":
            self.next_mode()

    def wait_keys_free(self, cancel):
        """Block until HOTKEY_QUIET has passed since the last hotkey (or cancel)."""
        while not cancel.is_set():
            with self.lock:
                left = self.last_hotkey + HOTKEY_QUIET - time.monotonic()
            if left <= 0:
                return
            time.sleep(min(left, 0.05))

    def next_mode(self):
        with self.lock:
            self.mode_index = (self.mode_index + 1) % len(self.modes)
            mode = self.modes[self.mode_index]
        system.save_mode(mode["name"], self.state_path)
        system.notify(f"Mode: {mode['name']}", " · ".join(f"{k} ≥ {v}" for k, v in mode["min"].items()))

    def toggle(self):
        with self.lock:
            if self.worker and self.worker.is_alive():
                if self.cancel.is_set():
                    # Stop already requested and the worker is still winding
                    # down (e.g. releasing a held key): queue the restart
                    # instead of dropping it; another toggle un-queues it.
                    self.restart_pending = not self.restart_pending
                else:
                    self.cancel.set()
                return
            self._start_locked()

    def _start_locked(self):
        self.restart_pending = False
        self.cancel = threading.Event()
        self.worker = threading.Thread(target=self._work, args=(self.cancel,), daemon=True)
        self.worker.start()

    def _work(self, cancel):
        try:
            self._scan(cancel)
        finally:
            with self.lock:
                if self.restart_pending and not self.stopping:
                    self._start_locked()

    def stop(self):
        with self.lock:
            self.stopping = True
            self.restart_pending = False
            self.cancel.set()
            worker = self.worker
        if worker:
            worker.join(timeout=2)  # let a held key be released first

    def _scan(self, cancel):
        try:
            pid = find_pid()
            base = module_base(pid) if pid else None
            if not base:
                raise NotReady("Megabonk process not found")
            game = Game(ProcessMemory(pid), base)
            game.check_classes()
            if not game.map_state().ready:
                raise NotReady("not in a run")
            hold = system.reset_hold_seconds()
            system.notify(f"Rerolling · {self.current_mode()[0]}", "Mod+F5 to stop")
            Scanner(
                game,
                reset=lambda: self.keyboard.hold(self.reset_key, hold),
                pause=lambda: self.keyboard.hold(self.pause_key, 0.05),
                focused=lambda: system.game_focused(pid),
                notify=system.notify,
                current_mode=self.current_mode,
                cancelled=cancel.is_set,
                keys_free=lambda: self.wait_keys_free(cancel),
            ).run()
        except Stop as e:
            system.notify("Rerolling stopped", str(e))
        except OffsetsOutdated as e:
            system.notify("bonk-reroll: offsets outdated",
                          f"Built for Megabonk build {BUILD}; the game has updated. ({e})")
        except NotReady as e:
            system.notify("bonk-reroll: game not ready",
                          f"{e}. Start a run first; if you're in one, the game may have "
                          f"updated (offsets are for build {BUILD}).")
        except ReadError as e:
            system.notify("bonk-reroll: memory read failed", f"{e} (if reads are denied, set kernel.yama.ptrace_scope = 0)")
        except Exception as e:  # keep the daemon alive; the hotkey can retry
            system.notify("bonk-reroll error", f"{type(e).__name__}: {e}")


def serve(daemon, child):
    """Pass socket commands to `daemon` until `child` exits; return its exit code."""
    path = socket_path()
    path.unlink(missing_ok=True)
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        server.bind(str(path))
        server.listen()
        server.settimeout(0.5)
        while child.poll() is None:
            try:
                conn, _ = server.accept()
            except TimeoutError:
                continue
            with conn:
                conn.settimeout(1)
                try:
                    command = conn.recv(64).decode(errors="replace").strip()
                except OSError:
                    continue
            try:
                daemon.handle(command)
            except Exception as e:  # a failing command must not end serving
                system.notify("bonk-reroll error", str(e))
    finally:
        daemon.stop()
        server.close()
        path.unlink(missing_ok=True)
    return child.returncode


def exit_code(returncode):
    """Shell-style status: a child killed by signal N exits 128 + N."""
    return 128 - returncode if returncode < 0 else returncode


def forward_signals(child):
    """Relay FORWARDED_SIGNALS to `child`; we keep serving until it exits.

    Returns a function that restores the previous handlers.
    """
    def relay(signum, _frame):
        child.send_signal(signum)  # no-op once the child has been reaped

    previous = {sig: signal.signal(sig, relay) for sig in FORWARDED_SIGNALS}
    return lambda: [signal.signal(sig, handler) for sig, handler in previous.items()]


def run(config_path, cmd):
    child = subprocess.Popen(cmd, env=child_env())
    restore = forward_signals(child)
    # Nothing below may keep the game from running or its exit code from Steam.
    try:
        daemon = Daemon(json.loads(Path(config_path).read_text()))
        return exit_code(serve(daemon, child))
    except Exception as e:
        system.notify("bonk-reroll disabled", str(e))
        return exit_code(child.wait())
    finally:
        restore()


def probe():
    pid = find_pid()
    try:
        base = module_base(pid) if pid else None
    except OSError:  # exited between find_pid and reading its maps
        base = None
    if not base:
        print("Megabonk is not running")
        return 1
    print(f"pid {pid}, GameAssembly.so at {base:#x}, offsets for build {BUILD}")
    game = Game(ProcessMemory(pid), base)
    try:
        game.check_classes()
        print("classes OK")
        print(game.map_state())
        labels, revision = game.feature_counts()
    except (NotReady, OffsetsOutdated, ReadError) as e:
        print(f"{type(e).__name__}: {e}")
        return 1
    print(f"revision {revision}")
    for label, count in sorted(labels.items()):
        print(f"  {label}: {count}")
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(prog="bonk-reroll")
    parser.add_argument("--config")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("run").add_argument("cmd", nargs=argparse.REMAINDER)
    for name in (*CLIENT_COMMANDS, "probe"):
        sub.add_parser(name)
    args = parser.parse_args(argv)
    if args.command == "run":
        if not args.config or not args.cmd:
            parser.error("run needs --config and a command")
        return run(args.config, args.cmd)
    if args.command == "probe":
        return probe()
    return send(args.command)


if __name__ == "__main__":
    sys.exit(main())
