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
