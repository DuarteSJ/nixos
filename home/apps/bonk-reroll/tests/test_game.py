import unittest

from bonk_reroll.game import SLOTS, Game, MapState, NotReady, OffsetsOutdated
from bonk_reroll.memory import ReadError
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
    mem.ptr(BASE, 0x0102_0146_4C45_7F)  # ELF header bytes at the module base
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
    def test_unreadable_game_is_read_error_not_outdated(self):
        with self.assertRaises(ReadError):
            Game(FakeMemory(), BASE).check_classes()

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
