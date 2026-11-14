import unittest

from bonk_reroll.rules import COUNTERS, counters_from_labels, describe, matches, validate

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


class Validate(unittest.TestCase):
    def test_known_counters_pass(self):
        validate([{"name": "perfect", "min": PERFECT}, {"name": "any", "min": {}}])

    def test_unknown_counter_raises(self):
        with self.assertRaisesRegex(ValueError, r"mode typo: unknown counter\(s\) shady_moai"):
            validate([{"name": "typo", "min": {"shady_moai": 9}}])

    def test_every_counter_is_accepted(self):
        validate([{"name": "all", "min": {key: 1 for key in COUNTERS}}])

    def test_no_modes_raises(self):
        with self.assertRaisesRegex(ValueError, "no modes"):
            validate([])

    def test_non_integer_minimum_raises(self):
        with self.assertRaisesRegex(ValueError, "integer"):
            validate([{"name": "x", "min": {"pots": "2"}}])
