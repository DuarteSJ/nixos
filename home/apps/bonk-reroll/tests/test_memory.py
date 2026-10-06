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
