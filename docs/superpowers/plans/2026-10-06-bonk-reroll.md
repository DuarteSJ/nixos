# bonk-reroll Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Megabonk map reroller that runs alongside the game, holds the quick-reset key until the map meets the active mode's minimums, then pauses the game.

**Architecture:** One Python package (`bonk_reroll`) packaged by a home-manager module. Pure logic (rules, IL2CPP memory decoding, the reroll loop) is separated from side effects (`/dev/uinput`, `hyprctl`, `dunstify`, files) so it's unit-tested against fakes; tests run inside the Nix build. `bonk-reroll run %command%` in Steam launch options spawns the game as a child and serves a unix socket that Hyprland keybinds talk to.

**Tech Stack:** Python 3.13 stdlib + `evdev`, ctypes `process_vm_readv`, Nix (`stdenvNoCC`, `makeShellWrapper`), home-manager, Hyprland Lua keybinds.

**Spec:** `docs/superpowers/specs/2026-10-06-bonk-reroll-design.md`

**Commits:** the user commits and pushes themselves. No commit steps; never commit.

**Running tests during development** (no system Python on this machine):

```bash
cd /home/duartesj/nixos/home/apps/bonk-reroll
nix shell --inputs-from /home/duartesj/nixos nixpkgs#python3 -c python3 -m unittest discover -s tests -t . -v
```

---

## File structure

All new files are under `home/apps/bonk-reroll/`:

| File | Responsibility |
|---|---|
| `bonk_reroll/__init__.py` | empty package marker |
| `bonk_reroll/rules.py` | counter keys ↔ game labels, `>=` mode evaluation, summaries |
| `bonk_reroll/memory.py` | `process_vm_readv` reader, `/proc` discovery, IL2CPP string/dictionary decoding |
| `bonk_reroll/game.py` | Megabonk offsets (build 21750826), class check, map state, feature counts |
| `bonk_reroll/scanner.py` | the reroll loop (no I/O; everything injected) |
| `bonk_reroll/system.py` | side effects: virtual keyboard, Hyprland focus, notifications, game config, mode state |
| `bonk_reroll/__main__.py` | CLI (`run`, `toggle`, `next-mode`, `probe`), daemon, socket |
| `tests/__init__.py` | empty |
| `tests/fakes.py` | `FakeMemory` sparse address space + dictionary layout helper |
| `tests/test_*.py` | one test module per source module |
| `default.nix` | home-manager module: package, config JSON, tests in `installCheckPhase`, `~/.local/bin` link |

Modified:

| File | Change |
|---|---|
| `home/apps/default.nix` | import `./bonk-reroll` |
| `home/desktop/hyprland/keybinds.nix` | `Mod+F5`, `Mod+Shift+F5` |
| `system/default.nix` | `hardware.uinput.enable` |
| `system/users.nix` | `uinput` group |
| `docs/superpowers/specs/2026-10-06-bonk-reroll-design.md` | mention `probe` subcommand |

---

### Task 1: rules — counters and mode evaluation

**Files:**
- Create: `home/apps/bonk-reroll/bonk_reroll/__init__.py` (empty)
- Create: `home/apps/bonk-reroll/tests/__init__.py` (empty)
- Create: `home/apps/bonk-reroll/bonk_reroll/rules.py`
- Test: `home/apps/bonk-reroll/tests/test_rules.py`

- [ ] **Step 1: Create the two empty `__init__.py` files.**

- [ ] **Step 2: Write the failing tests** — `tests/test_rules.py`:

```python
import unittest

from bonk_reroll.rules import COUNTERS, counters_from_labels, describe, matches

PERFECT = {"microwaves": 2, "boss_curses": 2, "shady_moais": 9}


class CountersFromLabels(unittest.TestCase):
    def test_maps_labels_and_sums_shady_moais(self):
        counts = counters_from_labels({"Moais": 5, "Shady Guy": 4, "Microwaves": 2})
        self.assertEqual(counts["moais"], 5)
        self.assertEqual(counts["shady"], 4)
        self.assertEqual(counts["shady_moais"], 9)
        self.assertEqual(counts["microwaves"], 2)

    def test_missing_labels_count_zero(self):
        counts = counters_from_labels({})
        self.assertEqual(counts["boss_curses"], 0)
        self.assertEqual(counts["shady_moais"], 0)

    def test_unknown_labels_are_ignored(self):
        self.assertEqual(set(counters_from_labels({"Mystery": 3})), set(COUNTERS))


class Matches(unittest.TestCase):
    def test_equal_to_minimum_matches(self):
        self.assertTrue(matches(PERFECT, {"microwaves": 2, "boss_curses": 2, "shady_moais": 9}))

    def test_above_minimum_matches(self):
        self.assertTrue(matches(PERFECT, {"microwaves": 3, "boss_curses": 4, "shady_moais": 12}))

    def test_one_counter_below_fails(self):
        self.assertFalse(matches(PERFECT, {"microwaves": 2, "boss_curses": 1, "shady_moais": 12}))

    def test_missing_counter_is_zero(self):
        self.assertFalse(matches({"pots": 1}, {}))

    def test_empty_mode_always_matches(self):
        self.assertTrue(matches({}, {}))


class Describe(unittest.TestCase):
    def test_lists_mode_counters_in_order(self):
        self.assertEqual(
            describe({"shady_moais": 9, "microwaves": 2}, {"shady_moais": 8, "microwaves": 2}),
            "shady_moais 8/9 · microwaves 2/2",
        )
```

- [ ] **Step 3: Run tests, verify they fail** (command at top). Expected: `ModuleNotFoundError: No module named 'bonk_reroll.rules'`.

- [ ] **Step 4: Implement** — `bonk_reroll/rules.py`:

```python
"""Mode evaluation: a map matches when every listed counter is >= its minimum."""

# Counter key -> label the game uses in InteractablesStatus.
# Keep in sync with `counters` in ../default.nix.
LABELS = {
    "moais": "Moais",
    "shady": "Shady Guy",
    "microwaves": "Microwaves",
    "boss_curses": "Boss Curses",
    "pots": "Pots",
    "chests": "Chests",
    "challenges": "Challenges",
    "charge_shrines": "Charge Shrines",
    "greed_shrines": "Greed Shrines",
    "magnet_shrines": "Magnet Shrines",
    "bald_heads": "Bald Heads",
}

# Derived counter key -> the counters it sums.
DERIVED = {"shady_moais": ("shady", "moais")}

COUNTERS = frozenset(LABELS) | frozenset(DERIVED)


def counters_from_labels(by_label):
    """Map {game label: count} to {counter key: count}; absent labels count 0."""
    counts = {key: by_label.get(label, 0) for key, label in LABELS.items()}
    for key, parts in DERIVED.items():
        counts[key] = sum(counts[part] for part in parts)
    return counts


def matches(minimums, counts):
    return all(counts.get(key, 0) >= need for key, need in minimums.items())


def describe(minimums, counts):
    """'shady_moais 8/9 · microwaves 2/2' for the counters a mode checks."""
    return " · ".join(f"{key} {counts.get(key, 0)}/{need}" for key, need in minimums.items())
```

- [ ] **Step 5: Run tests, verify they pass.** Expected: 9 tests, `OK`.

---

### Task 2: memory — process access and IL2CPP decoding

**Files:**
- Create: `home/apps/bonk-reroll/tests/fakes.py`
- Create: `home/apps/bonk-reroll/bonk_reroll/memory.py`
- Test: `home/apps/bonk-reroll/tests/test_memory.py`

- [ ] **Step 1: Write the test fakes** — `tests/fakes.py`:

```python
"""Test doubles: a sparse little-endian address space."""
import struct

from bonk_reroll.memory import ReadError


class FakeMemory:
    def __init__(self):
        self.bytes = {}

    def write(self, addr, data):
        for i, b in enumerate(data):
            self.bytes[addr + i] = b

    def u8(self, addr, value):
        self.write(addr, bytes([value]))

    def i32(self, addr, value):
        self.write(addr, struct.pack("<i", value))

    def ptr(self, addr, value):
        self.write(addr, struct.pack("<Q", value))

    def cstring(self, addr, text):
        # Trailing padding so 16-byte chunked reads past the NUL stay mapped.
        self.write(addr, text.encode() + b"\0" * 17)

    def managed_string(self, addr, text):
        self.i32(addr + 0x10, len(text))
        self.write(addr + 0x14, text.encode("utf-16-le"))

    def read(self, addr, size):
        try:
            return bytes(self.bytes[addr + i] for i in range(size))
        except KeyError:
            raise ReadError(f"unmapped {addr:#x}") from None


def counter_dict(mem, addr, entries, items, version=1, heap=0x9000_0000):
    """Lay out a Dictionary<string, Container> holding {label: max}."""
    mem.ptr(addr + 0x18, entries)
    mem.i32(addr + 0x20, len(items))
    mem.i32(addr + 0x2C, version)
    for i, (label, maximum) in enumerate(items.items()):
        key = heap + i * 0x100
        value = key + 0x80
        entry = entries + 0x20 + i * 0x18
        mem.i32(entry, 0)        # hashCode
        mem.i32(entry + 4, -1)   # next
        mem.ptr(entry + 0x08, key)
        mem.ptr(entry + 0x10, value)
        mem.managed_string(key, label)
        mem.i32(value + 0x10, maximum)
        mem.i32(value + 0x14, 0)
```

- [ ] **Step 2: Write the failing tests** — `tests/test_memory.py`:

```python
import ctypes
import os
import tempfile
import unittest

from bonk_reroll.memory import (
    ProcessMemory,
    ReadError,
    find_pid,
    module_base,
    read_counter_dict,
    read_cstring,
    read_managed_string,
)
from tests.fakes import FakeMemory, counter_dict

DICT = 0x1000
ENTRIES = 0x2000


class Strings(unittest.TestCase):
    def test_cstring_longer_than_one_chunk(self):
        mem = FakeMemory()
        mem.cstring(0x100, "MapGenerationController")
        self.assertEqual(read_cstring(mem, 0x100), "MapGenerationController")

    def test_managed_string(self):
        mem = FakeMemory()
        mem.managed_string(0x100, "Shady Guy")
        self.assertEqual(read_managed_string(mem, 0x100), "Shady Guy")

    def test_managed_string_rejects_implausible_length(self):
        mem = FakeMemory()
        mem.i32(0x110, 100_000)
        with self.assertRaises(ReadError):
            read_managed_string(mem, 0x100)

    def test_managed_string_rejects_undecodable(self):
        mem = FakeMemory()
        mem.i32(0x110, 1)
        mem.write(0x114, b"\x00\xd8")  # lone UTF-16 high surrogate
        with self.assertRaises(ReadError):
            read_managed_string(mem, 0x100)


class ProcessMemoryTests(unittest.TestCase):
    """process_vm_readv against our own process (always permitted)."""

    def test_reads_own_memory(self):
        buf = ctypes.create_string_buffer(b"hello\0")
        self.assertEqual(ProcessMemory(os.getpid()).read(ctypes.addressof(buf), 5), b"hello")

    def test_zero_size_read(self):
        buf = ctypes.create_string_buffer(b"x")
        self.assertEqual(ProcessMemory(os.getpid()).read(ctypes.addressof(buf), 0), b"")

    def test_unmapped_address_raises(self):
        with self.assertRaises(ReadError):
            ProcessMemory(os.getpid()).read(0, 4)


class CounterDict(unittest.TestCase):
    def test_reads_labels_and_max(self):
        mem = FakeMemory()
        counter_dict(mem, DICT, ENTRIES, {"Moais": 5, "Microwaves": 2})
        labels, _ = read_counter_dict(mem, DICT)
        self.assertEqual(labels, {"Moais": 5, "Microwaves": 2})

    def test_skips_freed_entries(self):
        mem = FakeMemory()
        counter_dict(mem, DICT, ENTRIES, {"Moais": 5, "Pots": 3})
        mem.ptr(ENTRIES + 0x20 + 0x08, 0)  # first entry's key cleared
        labels, _ = read_counter_dict(mem, DICT)
        self.assertEqual(labels, {"Pots": 3})

    def test_revision_changes_with_version(self):
        mem = FakeMemory()
        counter_dict(mem, DICT, ENTRIES, {"Moais": 5}, version=1)
        _, first = read_counter_dict(mem, DICT)
        mem.i32(DICT + 0x2C, 2)
        _, second = read_counter_dict(mem, DICT)
        self.assertNotEqual(first, second)

    def test_rejects_null_entries_array(self):
        mem = FakeMemory()
        counter_dict(mem, DICT, ENTRIES, {"Moais": 5})
        mem.ptr(DICT + 0x18, 0)
        with self.assertRaises(ReadError):
            read_counter_dict(mem, DICT)

    def test_rejects_dictionary_mutated_during_read(self):
        class Mutating(FakeMemory):
            reads = 0

            def read(self, addr, size):
                data = super().read(addr, size)
                self.reads += 1
                if self.reads == 4:  # header is 3 reads, then the entries block
                    self.i32(DICT + 0x2C, 99)
                return data

        mem = Mutating()
        counter_dict(mem, DICT, ENTRIES, {"Moais": 5})
        with self.assertRaises(ReadError):
            read_counter_dict(mem, DICT)


class ProcDiscovery(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.proc = self.tmp.name
        self.addCleanup(self.tmp.cleanup)

    def make_proc(self, pid, comm, maps=""):
        os.makedirs(f"{self.proc}/{pid}")
        with open(f"{self.proc}/{pid}/comm", "w") as f:
            f.write(comm + "\n")
        with open(f"{self.proc}/{pid}/maps", "w") as f:
            f.write(maps)

    def test_find_pid_by_comm(self):
        self.make_proc(10, "steam")
        self.make_proc(42, "Megabonk.x86_64")
        os.makedirs(f"{self.proc}/self")
        self.assertEqual(find_pid(proc=self.proc), 42)

    def test_find_pid_none(self):
        self.make_proc(10, "steam")
        self.assertIsNone(find_pid(proc=self.proc))

    def test_module_base_is_lowest_mapping(self):
        game = "/home/u/.local/share/Steam/steamapps/common/Megabonk"
        self.make_proc(42, "Megabonk.x86_64", maps=(
            f"7f0000002000-7f0000003000 r-xp 00001000 103:06 1 {game}/GameAssembly.so\n"
            f"7f0000001000-7f0000002000 r--p 00000000 103:06 1 {game}/GameAssembly.so\n"
            f"7f0000000000-7f0000001000 r--p 00000000 103:06 2 {game}/UnityPlayer.so\n"
        ))
        self.assertEqual(module_base(42, proc=self.proc), 0x7F0000001000)

    def test_module_base_missing(self):
        self.make_proc(42, "Megabonk.x86_64", maps="")
        self.assertIsNone(module_base(42, proc=self.proc))
```

- [ ] **Step 3: Run tests, verify they fail.** Expected: `ModuleNotFoundError: No module named 'bonk_reroll.memory'` (from `tests.fakes` import).

- [ ] **Step 4: Implement** — `bonk_reroll/memory.py`:

```python
"""Reading another process's memory, plus IL2CPP object decoding.

Everything that interprets bytes takes a `reader` with one method,
`read(addr, size) -> bytes`, so tests can substitute a fake address space.
"""
import ctypes
import os
import struct


class ReadError(Exception):
    """A read failed or returned data that can't be trusted."""


class _IOVec(ctypes.Structure):
    _fields_ = [("base", ctypes.c_void_p), ("len", ctypes.c_size_t)]


_libc = ctypes.CDLL(None, use_errno=True)
_libc.process_vm_readv.argtypes = [
    ctypes.c_int, ctypes.POINTER(_IOVec), ctypes.c_ulong,
    ctypes.POINTER(_IOVec), ctypes.c_ulong, ctypes.c_ulong,
]
_libc.process_vm_readv.restype = ctypes.c_ssize_t


class ProcessMemory:
    """Reads via process_vm_readv; needs kernel.yama.ptrace_scope = 0."""

    def __init__(self, pid):
        self.pid = pid

    def read(self, addr, size):
        buf = ctypes.create_string_buffer(size)
        local = _IOVec(ctypes.cast(buf, ctypes.c_void_p), size)
        remote = _IOVec(addr, size)
        n = _libc.process_vm_readv(self.pid, ctypes.byref(local), 1, ctypes.byref(remote), 1, 0)
        if n != size:
            why = os.strerror(ctypes.get_errno()) if n < 0 else f"short read ({n})"
            raise ReadError(f"read {size} bytes at {addr:#x}: {why}")
        return buf.raw


def find_pid(comm="Megabonk.x86_64", proc="/proc"):
    for entry in os.listdir(proc):
        if not entry.isdigit():
            continue
        try:
            with open(f"{proc}/{entry}/comm") as f:
                if f.read().strip() == comm[:15]:  # comm is truncated to 15 chars
                    return int(entry)
        except OSError:
            continue
    return None


def module_base(pid, name="GameAssembly.so", proc="/proc"):
    """Lowest mapped address of the shared object `name` in `pid`."""
    lowest = None
    with open(f"{proc}/{pid}/maps") as f:
        for line in f:
            fields = line.split(maxsplit=5)
            if len(fields) == 6 and fields[5].rstrip("\n").endswith("/" + name):
                start = int(fields[0].split("-")[0], 16)
                lowest = start if lowest is None else min(lowest, start)
    return lowest


def u8(reader, addr):
    return reader.read(addr, 1)[0]


def i32(reader, addr):
    return struct.unpack("<i", reader.read(addr, 4))[0]


def ptr(reader, addr):
    return struct.unpack("<Q", reader.read(addr, 8))[0]


def read_cstring(reader, addr, limit=128):
    out = b""
    while len(out) < limit:
        chunk = reader.read(addr + len(out), 16)
        end = chunk.find(b"\0")
        if end >= 0:
            return (out + chunk[:end]).decode("utf-8", "replace")
        out += chunk
    raise ReadError(f"unterminated string at {addr:#x}")


# System.String
STRING_LENGTH = 0x10
STRING_CHARS = 0x14


def read_managed_string(reader, addr):
    length = i32(reader, addr + STRING_LENGTH)
    if not 0 <= length <= 256:
        raise ReadError(f"implausible string length {length} at {addr:#x}")
    try:
        return reader.read(addr + STRING_CHARS, length * 2).decode("utf-16-le")
    except UnicodeDecodeError as e:
        raise ReadError(f"undecodable string at {addr:#x}") from e


# Dictionary<string, Container>
DICT_ENTRIES = 0x18
DICT_COUNT = 0x20
DICT_VERSION = 0x2C
ARRAY_DATA = 0x20
ENTRY_SIZE = 0x18
ENTRY_KEY = 0x08     # entry: hashCode i32, next i32, key ptr, value ptr
CONTAINER_MAX = 0x10


def _dict_header(reader, addr):
    return (
        ptr(reader, addr + DICT_ENTRIES),
        i32(reader, addr + DICT_COUNT),
        i32(reader, addr + DICT_VERSION),
    )


def read_counter_dict(reader, addr):
    """({label: max}, revision) of a Dictionary<string, Container>.

    The revision identifies this exact dictionary state; it changes when the
    game rebuilds or mutates the dictionary, i.e. on a new map."""
    header = _dict_header(reader, addr)
    entries, count, _version = header
    if not entries or not 0 <= count <= 256:
        raise ReadError(f"dictionary at {addr:#x} not ready")
    raw = reader.read(entries + ARRAY_DATA, count * ENTRY_SIZE)
    result = {}
    for i in range(count):
        key, value = struct.unpack_from("<QQ", raw, i * ENTRY_SIZE + ENTRY_KEY)
        if key and value:  # removed entries have their key cleared
            result[read_managed_string(reader, key)] = i32(reader, value + CONTAINER_MAX)
    if _dict_header(reader, addr) != header:
        raise ReadError("dictionary changed while reading")
    return result, (addr, *header)
```

- [ ] **Step 5: Run tests, verify they pass.** Expected: all `test_memory` and `test_rules` tests `OK`.

---

### Task 3: game — Megabonk layout

**Files:**
- Create: `home/apps/bonk-reroll/bonk_reroll/game.py`
- Test: `home/apps/bonk-reroll/tests/test_game.py`

- [ ] **Step 1: Write the failing tests** — `tests/test_game.py`:

```python
import unittest

from bonk_reroll.game import SLOTS, Game, MapState, NotReady, OffsetsOutdated
from tests.fakes import FakeMemory, counter_dict

BASE = 0x7F00_0000_0000
KLASS = {
    "InteractablesStatus": 0x5000_0000_0000,
    "MapController": 0x5000_0001_0000,
    "MapGenerationController": 0x5000_0002_0000,
}
STATICS = {name: klass + 0x0100_0000_0000 for name, klass in KLASS.items()}


def install(mem, names=None):
    """Lay out all three classes; `names` overrides the stored class names."""
    names = names or {}
    for name, klass in KLASS.items():
        mem.ptr(BASE + SLOTS[name], klass)
        mem.ptr(klass + 0x10, klass + 0x400)
        mem.cstring(klass + 0x400, names.get(name, name))
        mem.ptr(klass + 0xB8, STATICS[name])


def set_map(mem, generating=0, resetting=0, seed=7, map_ptr=0xA0, stage_ptr=0xB0):
    gen, ctl = STATICS["MapGenerationController"], STATICS["MapController"]
    mem.u8(gen + 0x10, generating)
    mem.i32(gen + 0x2C, seed)
    mem.ptr(ctl + 0x10, map_ptr)
    mem.ptr(ctl + 0x18, stage_ptr)
    mem.u8(ctl + 0x21, resetting)


class CheckClasses(unittest.TestCase):
    def test_passes_when_names_match(self):
        mem = FakeMemory()
        install(mem)
        Game(mem, BASE).check_classes()

    def test_wrong_name_means_outdated(self):
        mem = FakeMemory()
        install(mem, names={"MapController": "SomethingElse"})
        with self.assertRaises(OffsetsOutdated):
            Game(mem, BASE).check_classes()

    def test_unreadable_slot_means_outdated(self):
        mem = FakeMemory()
        install(mem)
        mem.ptr(KLASS["MapController"] + 0x10, 0xDEAD_0000_0000)  # name ptr into nowhere
        with self.assertRaises(OffsetsOutdated):
            Game(mem, BASE).check_classes()

    def test_non_pointer_slot_means_outdated(self):
        mem = FakeMemory()
        install(mem)
        mem.ptr(BASE + SLOTS["MapController"], 0xFFFF_FFFF_FFFF_0000)
        with self.assertRaises(OffsetsOutdated):
            Game(mem, BASE).check_classes()

    def test_null_name_pointer_means_outdated(self):
        mem = FakeMemory()
        install(mem)
        mem.ptr(KLASS["MapController"] + 0x10, 0)
        with self.assertRaises(OffsetsOutdated):
            Game(mem, BASE).check_classes()

    def test_metadata_token_means_not_ready(self):
        mem = FakeMemory()
        install(mem)
        mem.ptr(BASE + SLOTS["MapController"], 0x2000_1234)
        with self.assertRaises(NotReady):
            Game(mem, BASE).check_classes()


class MapStateTests(unittest.TestCase):
    def test_reads_fields(self):
        mem = FakeMemory()
        install(mem)
        set_map(mem, generating=1, resetting=0, seed=42, map_ptr=0xA0, stage_ptr=0xB0)
        self.assertEqual(Game(mem, BASE).map_state(), MapState(True, False, 42, 0xA0, 0xB0))

    def test_ready_needs_idle_and_pointers(self):
        self.assertTrue(MapState(False, False, 1, 0xA0, 0xB0).ready)
        self.assertFalse(MapState(True, False, 1, 0xA0, 0xB0).ready)
        self.assertFalse(MapState(False, True, 1, 0xA0, 0xB0).ready)
        self.assertFalse(MapState(False, False, 1, 0, 0xB0).ready)

    def test_null_statics_not_ready(self):
        mem = FakeMemory()
        install(mem)
        mem.ptr(KLASS["MapController"] + 0xB8, 0)
        with self.assertRaises(NotReady):
            Game(mem, BASE).map_state()


class FeatureCounts(unittest.TestCase):
    def test_reads_interactables_dictionary(self):
        mem = FakeMemory()
        install(mem)
        mem.ptr(STATICS["InteractablesStatus"], 0x3000)
        counter_dict(mem, 0x3000, 0x4000, {"Moais": 4, "Shady Guy": 5})
        labels, _ = Game(mem, BASE).feature_counts()
        self.assertEqual(labels, {"Moais": 4, "Shady Guy": 5})

    def test_null_dictionary_not_ready(self):
        mem = FakeMemory()
        install(mem)
        mem.ptr(STATICS["InteractablesStatus"], 0)
        with self.assertRaises(NotReady):
            Game(mem, BASE).feature_counts()
```

- [ ] **Step 2: Run tests, verify they fail.** Expected: `ModuleNotFoundError: No module named 'bonk_reroll.game'`.

- [ ] **Step 3: Implement** — `bonk_reroll/game.py`:

```python
"""Megabonk's memory layout for Steam build 21750826 (Linux GameAssembly.so).

Offsets are facts taken from the cybWasHere/BonkScanner Linux port's offset
table. A game update moves the class slots; check_classes() catches that
before anything acts on the numbers.
"""
from dataclasses import dataclass

from .memory import ReadError, i32, ptr, read_counter_dict, read_cstring, u8

BUILD = "21750826"

# GameAssembly.so offset of each class's TypeInfo pointer.
SLOTS = {
    "InteractablesStatus": 0x515A300,
    "MapController": 0x515AFC0,
    "MapGenerationController": 0x515AFD8,
}
CLASS_NAME = 0x10     # Il2CppClass.name (char*)
STATIC_FIELDS = 0xB8  # Il2CppClass.static_fields

# Static field offsets.
INTERACTABLES_DICT = 0x0
GEN_IS_GENERATING = 0x10
GEN_SEED = 0x2C
MAP_CURRENT_MAP = 0x10
MAP_CURRENT_STAGE = 0x18
MAP_RESETTING = 0x21


class NotReady(Exception):
    """The game hasn't initialised what we need yet (e.g. still in a menu)."""


class OffsetsOutdated(Exception):
    """The class slots don't hold the expected classes: the game updated."""


@dataclass(frozen=True)
class MapState:
    generating: bool
    resetting: bool
    seed: int
    map_ptr: int
    stage_ptr: int

    @property
    def ready(self):
        return not self.generating and not self.resetting and bool(self.map_ptr) and bool(self.stage_ptr)

    @property
    def identity(self):
        return (self.seed, self.map_ptr, self.stage_ptr)


class Game:
    def __init__(self, reader, base):
        self.reader = reader
        self.base = base

    def _class(self, name):
        klass = ptr(self.reader, self.base + SLOTS[name])
        # Until IL2CPP initialises a class its slot holds a small metadata
        # token rather than a pointer.
        if klass < 1 << 32:
            raise NotReady(f"{name} not initialised")
        # Above the 47-bit user-space limit it can't be a pointer at all:
        # the slot moved (check_classes reports that as OffsetsOutdated).
        if klass >= 1 << 47:
            raise ReadError(f"{name} slot holds non-pointer {klass:#x}")
        return klass

    def _statics(self, name):
        statics = ptr(self.reader, self._class(name) + STATIC_FIELDS)
        if not statics:
            raise NotReady(f"{name} statics not allocated")
        return statics

    def check_classes(self):
        for name in SLOTS:
            try:
                klass = self._class(name)
                actual = read_cstring(self.reader, ptr(self.reader, klass + CLASS_NAME))
            except ReadError as e:
                raise OffsetsOutdated(f"{name}: {e}") from e
            if actual != name:
                raise OffsetsOutdated(f"slot for {name} holds {actual!r}")

    def map_state(self):
        gen = self._statics("MapGenerationController")
        ctl = self._statics("MapController")
        r = self.reader
        return MapState(
            generating=u8(r, gen + GEN_IS_GENERATING) != 0,
            resetting=u8(r, ctl + MAP_RESETTING) != 0,
            seed=i32(r, gen + GEN_SEED),
            map_ptr=ptr(r, ctl + MAP_CURRENT_MAP),
            stage_ptr=ptr(r, ctl + MAP_CURRENT_STAGE),
        )

    def feature_counts(self):
        """({label: max}, revision) of the current map's interactables."""
        d = ptr(self.reader, self._statics("InteractablesStatus") + INTERACTABLES_DICT)
        if not d:
            raise NotReady("interactables dictionary not allocated")
        return read_counter_dict(self.reader, d)
```

- [ ] **Step 4: Run tests, verify they pass.**

---

### Task 4: scanner — the reroll loop

**Files:**
- Create: `home/apps/bonk-reroll/bonk_reroll/scanner.py`
- Test: `home/apps/bonk-reroll/tests/test_scanner.py`

- [ ] **Step 1: Write the failing tests** — `tests/test_scanner.py`:

```python
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
```

- [ ] **Step 2: Run tests, verify they fail.** Expected: `ModuleNotFoundError: No module named 'bonk_reroll.scanner'`.

- [ ] **Step 3: Implement** — `bonk_reroll/scanner.py`:

```python
"""The reroll loop. All I/O is injected so it can be tested with fakes."""
import time

from .game import NotReady
from .memory import ReadError
from .rules import counters_from_labels, describe, matches


class Stop(Exception):
    """Rerolling ended without a match; the message says why."""


class Scanner:
    def __init__(self, game, *, reset, pause, focused, notify, current_mode, cancelled,
                 sleep=time.sleep, clock=time.monotonic, timeout=10.0, poll=0.01, settle=0.025):
        self.game = game
        self.reset = reset
        self.pause = pause
        self.focused = focused
        self.notify = notify
        self.current_mode = current_mode
        self.cancelled = cancelled
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
            if self.cancelled():
                raise Stop("cancelled")
            if not self.focused():
                raise Stop("Megabonk lost focus")
            self.reset()
            rerolls += 1
            counts = counters_from_labels(self._wait_for_new_map(before, before_rev))
            name, minimums = self.current_mode()
            if matches(minimums, counts):
                if self.focused():
                    self.pause()
                self.notify(f"{name} map after {rerolls} rerolls", describe(minimums, counts))
                return
            self.notify(f"Reroll #{rerolls} · {name}", describe(minimums, counts))

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
```

- [ ] **Step 4: Run tests, verify they pass.**

---

### Task 5: system — side effects

**Files:**
- Create: `home/apps/bonk-reroll/bonk_reroll/system.py`
- Test: `home/apps/bonk-reroll/tests/test_system.py`

- [ ] **Step 1: Write the failing tests** — `tests/test_system.py`:

```python
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
```

- [ ] **Step 2: Run tests, verify they fail.** Expected: `ImportError: cannot import name 'system'`.

- [ ] **Step 3: Implement** — `bonk_reroll/system.py`:

```python
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
```

- [ ] **Step 4: Run tests, verify they pass.**

---

### Task 6: CLI, daemon and socket

> **Post-review:** hardened after code review. `run` now starts the game before reading the config, `exit_code` maps signal deaths to 128+N, and serving survives errors from `handle`. `stop` joins the worker, `_scan` has a catch-all notification, and `probe` tolerates the game exiting. More tests were added. The files in `home/apps/bonk-reroll/` are authoritative; the code blocks below are the pre-review baseline.

**Files:**
- Create: `home/apps/bonk-reroll/bonk_reroll/__main__.py`
- Test: `home/apps/bonk-reroll/tests/test_main.py`
- Modify: `docs/superpowers/specs/2026-10-06-bonk-reroll-design.md` (Process model section)

- [ ] **Step 1: Write the failing tests** — `tests/test_main.py`:

```python
import os
import tempfile
import threading
import time
import unittest
from pathlib import Path
from unittest import mock

from bonk_reroll.__main__ import child_env, send, serve


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

    def test_send_without_daemon_notifies(self):
        with mock.patch("bonk_reroll.system.notify") as notify:
            self.assertEqual(send("toggle"), 1)
        notify.assert_called_once()
```

- [ ] **Step 2: Run tests, verify they fail.** Expected: `ModuleNotFoundError: No module named 'bonk_reroll.__main__'`.

- [ ] **Step 3: Implement** — `bonk_reroll/__main__.py`:

```python
"""bonk-reroll: Megabonk map reroller.

  bonk-reroll --config FILE run CMD...   run CMD (the game) and serve hotkeys
  bonk-reroll toggle                      start/stop rerolling
  bonk-reroll next-mode                   cycle the active mode
  bonk-reroll probe                       print what it reads from the game
"""
import argparse
import json
import os
import socket
import subprocess
import sys
import threading
from pathlib import Path

from . import system
from .game import BUILD, Game, NotReady, OffsetsOutdated
from .memory import ProcessMemory, ReadError, find_pid, module_base
from .scanner import Scanner, Stop

CLIENT_COMMANDS = ("toggle", "next-mode")
# Steam sets these for the game. The wrapper stashes them under STASH_PREFIX
# and unsets them so our Nix Python runs clean; run() restores them for CMD.
STASHED = ("LD_LIBRARY_PATH", "LD_PRELOAD")
STASH_PREFIX = "BONK_REROLL_ORIG_"


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
        self.modes = config["modes"]
        self.reset_key = config["reset_key"]
        self.pause_key = config["pause_key"]
        self.state_path = system.state_file()
        self.mode_index = system.load_mode_index([m["name"] for m in self.modes], self.state_path)
        self.keyboard = system.VirtualKeyboard([self.reset_key, self.pause_key])
        self.lock = threading.Lock()
        self.cancel = threading.Event()
        self.worker = None

    def current_mode(self):
        with self.lock:
            mode = self.modes[self.mode_index]
        return mode["name"], mode["min"]

    def handle(self, command):
        if command == "toggle":
            self.toggle()
        elif command == "next-mode":
            self.next_mode()

    def next_mode(self):
        with self.lock:
            self.mode_index = (self.mode_index + 1) % len(self.modes)
            mode = self.modes[self.mode_index]
        system.save_mode(mode["name"], self.state_path)
        system.notify(f"Mode: {mode['name']}", " · ".join(f"{k} ≥ {v}" for k, v in mode["min"].items()))

    def toggle(self):
        if self.worker and self.worker.is_alive():
            self.cancel.set()
            return
        self.cancel = threading.Event()
        self.worker = threading.Thread(target=self._scan, args=(self.cancel,), daemon=True)
        self.worker.start()

    def stop(self):
        self.cancel.set()

    def _scan(self, cancel):
        try:
            pid = find_pid()
            base = module_base(pid) if pid else None
            if not base:
                raise NotReady("Megabonk process not found")
            game = Game(ProcessMemory(pid), base)
            game.check_classes()
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
            system.notify("bonk-reroll: memory read failed", f"{e} (kernel.yama.ptrace_scope must be 0)")


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
            daemon.handle(command)
    finally:
        daemon.stop()
        server.close()
        path.unlink(missing_ok=True)
    return child.returncode


def run(config_path, cmd):
    config = json.loads(Path(config_path).read_text())
    child = subprocess.Popen(cmd, env=child_env())
    try:
        daemon = Daemon(config)
    except Exception as e:  # never keep the game from running
        system.notify("bonk-reroll disabled", str(e))
        return child.wait()
    return serve(daemon, child)


def probe():
    pid = find_pid()
    base = module_base(pid) if pid else None
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
```

- [ ] **Step 4: Run tests, verify they pass.** Expected: all modules `OK`.

- [ ] **Step 5: Add `probe` to the spec.** In `docs/superpowers/specs/2026-10-06-bonk-reroll-design.md`, under "## Process model", append the bullet:

```markdown
- `bonk-reroll probe` prints pid, module base, class check, map state and the
  raw label counts — for verifying offsets after a game update.
```

---

### Task 7: Nix package and home-manager module

**Files:**
- Create: `home/apps/bonk-reroll/default.nix`
- Modify: `home/apps/default.nix`

- [ ] **Step 1: Write the module** — `home/apps/bonk-reroll/default.nix`:

```nix
# bonk-reroll: Megabonk map reroller.
# Spec: docs/superpowers/specs/2026-10-06-bonk-reroll-design.md
#
# Steam launch options for Megabonk:
#   nvidia-offload gamemoderun $HOME/.local/bin/bonk-reroll run %command%
# ($HOME/.local/bin because Steam's FHS sandbox can't see /etc/profiles.)
{
  lib,
  pkgs,
  osConfig,
  ...
}: let
  # Keep in sync with LABELS/DERIVED in bonk_reroll/rules.py.
  counters = [
    "moais"
    "shady"
    "shady_moais"
    "microwaves"
    "boss_curses"
    "pots"
    "chests"
    "challenges"
    "charge_shrines"
    "greed_shrines"
    "magnet_shrines"
    "bald_heads"
  ];

  # Cycled in this order by Mod+Shift+F5. A map matches when every count is
  # >= its number.
  modes = [
    {
      name = "perfect";
      min = {
        microwaves = 2;
        boss_curses = 2;
        shady_moais = 9;
      };
    }
    {
      name = "good";
      min = {
        microwaves = 2;
        boss_curses = 2;
        shady_moais = 8;
      };
    }
  ];

  checkMode = mode:
    lib.throwIfNot (lib.all (k: lib.elem k counters) (lib.attrNames mode.min))
    "bonk-reroll: mode ${mode.name} uses an unknown counter"
    mode;

  configFile = pkgs.writeText "bonk-reroll.json" (builtins.toJSON {
    modes = map checkMode modes;
    reset_key = "KEY_Q"; # Megabonk's QuickReset binding
    pause_key = "KEY_ESC";
  });

  python = pkgs.python3.withPackages (ps: [ps.evdev]);

  bonk-reroll = pkgs.stdenvNoCC.mkDerivation {
    pname = "bonk-reroll";
    version = "0.1.0";
    src = lib.fileset.toSource {
      root = ./.;
      fileset = lib.fileset.unions [./bonk_reroll ./tests];
    };
    nativeBuildInputs = [pkgs.makeShellWrapper];
    dontBuild = true;

    # Steam sets LD_LIBRARY_PATH (runtime libs) and LD_PRELOAD (overlay) for
    # the launch command: stash them for the game, keep them out of our Python.
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/bonk-reroll $out/bin
      cp -r bonk_reroll $out/lib/bonk-reroll/
      makeShellWrapper ${python.interpreter} $out/bin/bonk-reroll \
        --run 'if [ -n "''${LD_LIBRARY_PATH+set}" ]; then export BONK_REROLL_ORIG_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"; unset LD_LIBRARY_PATH; fi' \
        --run 'if [ -n "''${LD_PRELOAD+set}" ]; then export BONK_REROLL_ORIG_LD_PRELOAD="$LD_PRELOAD"; unset LD_PRELOAD; fi' \
        --prefix PATH : ${lib.makeBinPath [osConfig.programs.hyprland.package pkgs.dunst]} \
        --set PYTHONPATH $out/lib/bonk-reroll \
        --add-flags "-m bonk_reroll --config ${configFile}"
      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      PYTHONPATH=$out/lib/bonk-reroll ${python.interpreter} -m unittest discover -s tests -t . -v
      runHook postInstallCheck
    '';

    meta.mainProgram = "bonk-reroll";
  };
in {
  home.packages = [bonk-reroll];
  home.file.".local/bin/bonk-reroll".source = lib.getExe bonk-reroll;
}
```

- [ ] **Step 2: Import it.** In `home/apps/default.nix`, add `./bonk-reroll` to `imports` after `./games.nix`:

```nix
    ./zathura.nix
    ./games.nix
    ./bonk-reroll
```

- [ ] **Step 3: Track new files** (flakes ignore untracked files):

```bash
cd /home/duartesj/nixos && git add home/apps/bonk-reroll
```

- [ ] **Step 4: Build the package; tests run in the build.**

```bash
cd /home/duartesj/nixos
nix build --no-link -L '.#nixosConfigurations.desktop.config.home-manager.users.duartesj.home.path' 2>&1 | grep -E "Ran [0-9]+ tests|^OK|FAILED|error" | head
```

Expected: `Ran N tests` and `OK`; no `error`.

- [ ] **Step 5: Smoke-test the CLI** (`probe` with the game closed; `toggle` with no daemon):

```bash
cd /home/duartesj/nixos
b=$(nix build --no-link --print-out-paths '.#nixosConfigurations.desktop.config.home-manager.users.duartesj.home.path')/bin/bonk-reroll
"$b" probe; echo "exit=$?"
"$b" toggle; echo "exit=$?"
```

Expected: `Megabonk is not running` / `exit=1` (or real output if the game is running), then a "bonk-reroll not running" dunst notification and `exit=1`.

- [ ] **Step 6: Smoke-test `run` with the env stash** (no game: `env` as the child; this needs `/dev/uinput`, so before Task 9 it falls back to "bonk-reroll disabled" and still runs the child):

```bash
LD_PRELOAD=/nonexistent-overlay.so "$b" run env | grep -E '^(LD_PRELOAD|BONK_REROLL)'
```

Expected: exactly `LD_PRELOAD=/nonexistent-overlay.so` (restored for the child, no `BONK_REROLL_*` leaking). A loader warning about the missing preload from `env` itself is fine.

---

### Task 8: Hyprland keybinds

**Files:**
- Modify: `home/desktop/hyprland/keybinds.nix` (the "Misc execs" list)

- [ ] **Step 1: Add the binds** after `(kb (modShiftKey "O") monitorStatus) # which monitor profile is active`:

```nix
    (kb (modKey "F5") (exec "bonk-reroll toggle")) # Megabonk reroller
    (kb (modShiftKey "F5") (exec "bonk-reroll next-mode"))
```

- [ ] **Step 2: Verify the generated Lua compiles and contains the binds.**

```bash
cd /home/duartesj/nixos
out=$(nix build --no-link --print-out-paths '.#nixosConfigurations.desktop.config.home-manager.users.duartesj.xdg.configFile."hypr/hyprland.lua".source')
nix shell nixpkgs#lua -c luac -p "$out" && echo LUAC_OK
grep -n "F5" "$out"
```

Expected: `LUAC_OK` and two `F5` bind lines.

---

### Task 9: System permissions

**Files:**
- Modify: `system/default.nix`
- Modify: `system/users.nix`

- [ ] **Step 1:** In `system/default.nix`, after the `programs = { ... };` block:

```nix
  # bonk-reroll (home/apps/bonk-reroll) presses quick reset through a virtual
  # keyboard. (Reading Megabonk's memory needs no sysctl: the game opts in to
  # being traced itself, verified with ptrace_scope = 1.)
  hardware.uinput.enable = true;
```

> **Post-verification:** `ptrace_scope = 0` was dropped. During Task 7, `bonk-reroll probe` read the live game with the default `ptrace_scope = 1`, from a process that is not the game's ancestor. Unity sets `PR_SET_PTRACER_ANY` for its crash handler.

- [ ] **Step 2:** In `system/users.nix`, change `extraGroups` to:

```nix
    extraGroups = ["wheel" "networkmanager" "gamemode" "uinput"];
```

(`uinput` only — NOT `input`, which would allow reading real keyboards.)

- [ ] **Step 3: Build the whole system.**

```bash
cd /home/duartesj/nixos
nix build --no-link --print-out-paths .#nixosConfigurations.desktop.config.system.build.toplevel 2>&1 | grep -E "error|^/nix/store"
```

Expected: a single `/nix/store/...-nixos-system-desktop-...` path.

---

### Task 10: Live verification (needs the user)

- [ ] **Step 1: User:** `sudo nixos-rebuild switch --flake /home/duartesj/nixos#desktop`, then log out and back in (`uinput` group).

- [ ] **Step 2: Verify permissions.**

```bash
id -nG | tr ' ' '\n' | grep -x uinput     # uinput
ls -la ~/.local/bin/bonk-reroll           # symlink into the store
```

- [ ] **Step 3: User:** set Megabonk's Steam launch options to
  `nvidia-offload gamemoderun /home/duartesj/.local/bin/bonk-reroll run %command%`, start the game, enter a run.

- [ ] **Step 4: Verify the daemon wraps the game and offsets resolve.**

```bash
g=$(pgrep -x Megabonk.x86_64); x=$g
for i in $(seq 8); do x=$(awk '{print $4}' /proc/$x/stat); [ "$x" -le 1 ] && break; echo "$x $(cat /proc/$x/comm)"; done | grep -i python
ls -la $XDG_RUNTIME_DIR/bonk-reroll.sock
bonk-reroll probe
```

Expected: a python ancestor of the game; the socket exists; `probe` prints `classes OK`, a `MapState(generating=False, ...)` and labels such as `Moais`, `Shady Guy`, `Microwaves`, `Boss Curses` with plausible counts. If `probe` reports `OffsetsOutdated`, stop: the installed build isn't 21750826.

- [ ] **Step 5: User:** cross-check `probe`'s counts against the in-game map / stats for the current run.

- [ ] **Step 6: User, in-game:** `Mod+Shift+F5` twice (mode notifications: good, then perfect). `Mod+F5`: rerolls start (one updating "Reroll #N" notification), stop on a matching map with the game paused and a "perfect map after N rerolls" notification. Then `Mod+F5` mid-reroll (stops: "cancelled"), and alt-tab mid-reroll (stops: "Megabonk lost focus").

- [ ] **Step 7: Quit the game.** Expected: the socket disappears and Steam behaves as before (`steam-game` shutdown logic unchanged).
