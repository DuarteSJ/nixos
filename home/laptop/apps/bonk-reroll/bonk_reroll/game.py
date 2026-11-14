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
        # Can we read the game at all? A denied read must surface as
        # ReadError (permissions), not as OffsetsOutdated.
        ptr(self.reader, self.base)
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
