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
