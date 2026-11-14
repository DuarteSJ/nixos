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
    """Reads via process_vm_readv (allowed: Megabonk opts in to being traced)."""

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
