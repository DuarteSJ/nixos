"""Mode evaluation: a map matches when every listed counter is >= its minimum."""

# Counter key -> label the game uses in InteractablesStatus.
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


def validate(modes):
    """Reject configs `matches` would silently misread (it counts unknown keys as 0)."""
    if not modes:
        raise ValueError("no modes configured")
    for mode in modes:
        name = mode.get("name")
        if not isinstance(name, str) or not name:
            raise ValueError(f"mode without a name: {mode!r}")
        minimums = mode.get("min")
        if not isinstance(minimums, dict):
            raise ValueError(f"mode {name}: 'min' must be a mapping of counter -> minimum")
        unknown = sorted(set(minimums) - COUNTERS)
        if unknown:
            raise ValueError(f"mode {name}: unknown counter(s) {', '.join(unknown)} "
                             f"(known: {', '.join(sorted(COUNTERS))})")
        for key, need in minimums.items():
            if isinstance(need, bool) or not isinstance(need, int):
                raise ValueError(f"mode {name}: minimum for {key} must be an integer, got {need!r}")


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
