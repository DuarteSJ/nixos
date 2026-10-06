# bonk-reroll — Megabonk map reroller

## Goal

Automatically quick-reset Megabonk runs until the generated map meets the
active mode's thresholds. Minimal, self-written replacement for BonkScanner's
reroll feature; no stats, overlay, or GUI.

## Behaviour

- Starts with the game, exits with it. Idle until toggled.
- `Mod+F5` toggles rerolling on/off.
- `Mod+Shift+F5` cycles the active mode; a dunst notification shows the new
  mode. Switching mid-reroll applies from the next map evaluated.
- While rerolling, each map is evaluated: if it matches, rerolling stops, the
  game is paused (tap `KEY_ESC` through the virtual keyboard, behind the same
  focus guard as resets) and a notification shows the mode and counts. If not, the quick-reset key is held
  again. A single notification (replaced in place via `dunstify -r`) shows the
  reroll number and the last map's counts.
- Rerolling stops (with a notification) when: a map matches, the toggle is
  pressed, Megabonk loses focus, a new map is not ready within 10 s, or memory
  reads fail.

## Modes

Defined in Nix, evaluated as "every listed count >= its threshold". Cycle order
is the order listed; the first is the default on first run. The last-used mode
is persisted in `$XDG_STATE_HOME/bonk-reroll/mode`.

```nix
modes = [
  { name = "perfect"; min = { microwaves = 2; boss_curses = 2; shady_moais = 9; }; }
  { name = "good";    min = { microwaves = 2; boss_curses = 2; shady_moais = 8; }; }
];
```

Counter keys and the in-game labels they map to (the `max` field, i.e. total
spawned on the map):

| key | label |
|---|---|
| `moais` | Moais |
| `shady` | Shady Guy |
| `shady_moais` | Shady Guy + Moais (derived sum) |
| `microwaves` | Microwaves |
| `boss_curses` | Boss Curses |
| `pots` | Pots |
| `chests` | Chests |
| `challenges` | Challenges |
| `charge_shrines` | Charge Shrines |
| `greed_shrines` | Greed Shrines |
| `magnet_shrines` | Magnet Shrines |
| `bald_heads` | Bald Heads |

Unknown keys in a mode are a Nix evaluation error (assert against this list).

## Process model

- Steam launch options for Megabonk become
  `nvidia-offload gamemoderun /home/duartesj/.local/bin/bonk-reroll run %command%`
  (absolute path: Steam's FHS sandbox does not see `/etc/profiles/per-user`;
  `/home`, `/run/user/1000`, `/run/current-system` and the Nix store are
  visible, and host, Steam sandbox and the game's pressure-vessel container
  share one PID namespace — verified live).
  Launch options apply whether the game is started from rofi or Steam.
- `bonk-reroll run <cmd...>` spawns `<cmd...>` as a child, serves a unix socket
  at `$XDG_RUNTIME_DIR/bonk-reroll.sock`, and exits with the child's exit code
  once the child exits (removing the socket).
- Steam sets `LD_LIBRARY_PATH` (Steam runtime libs) and `LD_PRELOAD` (overlay)
  for the launch command. The shell wrapper stashes them as
  `BONK_REROLL_ORIG_*` and unsets them so the Nix Python runs clean; `run`
  restores them for `<cmd...>` only.
- `run` never blocks the game: if the daemon can't start (e.g. no
  `/dev/uinput` access) it notifies and just waits for the child.
- `bonk-reroll toggle` / `bonk-reroll next-mode` are clients: they send one
  line to the socket. If no daemon is listening, they notify
  "bonk-reroll: not running (launch Megabonk with the launch option)".
- The scanner itself runs in a worker thread inside the daemon; socket commands
  set flags it checks between steps.
- `bonk-reroll probe` prints pid, module base, class check, map state and the
  raw label counts — for verifying offsets after a game update.

## Memory reading

- Game process: scan `/proc/*/comm` for `Megabonk.x86_64`. Module base: lowest
  mapping of `GameAssembly.so` in `/proc/<pid>/maps`. Reads via
  `process_vm_readv` (ctypes). Works with the default
  `kernel.yama.ptrace_scope = 1`. The game opts in to being traced
  (`PR_SET_PTRACER_ANY`, Unity's crash handler), which was verified live. If a
  future build stops doing that, the read-failure notification points at
  `ptrace_scope = 0`.
- Offsets are hardcoded for Steam build `21750826` (source: the
  cybWasHere/BonkScanner Linux port's `offsets.py`; facts only, no code
  copied). Static fields of a class: `[[base + slot] + 0xB8]`.
  - `InteractablesStatus` slot `0x515A300`
  - `MapController` slot `0x515AFC0`
  - `MapGenerationController` slot `0x515AFD8`
- **Build check before use:** follow each slot to its `Il2CppClass`, read the
  class name string at `+0x10`, compare to the expected name. Any mismatch →
  notify "offsets outdated for this game build" and refuse to reroll.
- **Feature counts:** `dict = [statics(InteractablesStatus) + 0x0]`, a
  `Dictionary<string, Container>`: entries array `[dict+0x18]`, count
  `i32 [dict+0x20]`, version `i32 [dict+0x2C]`. Entry `i` at
  `entries + 0x20 + i*0x18`: key ptr `+0x8`, value ptr `+0x10`. Key is a
  managed string (length `i32 +0x10`, UTF-16 at `+0x14`). Value: `max`
  `i32 +0x10`. Re-read dict/entries/count/version after the walk; if any
  changed, discard and retry.
- **Map ready:** `MapGenerationController` statics: `isGenerating` byte
  `+0x10`, `mapSeed` i32 `+0x2C`. `MapController` statics: `currentMap` ptr
  `+0x10`, `currentStage` ptr `+0x18`, `reseting` byte `+0x21`. Ready = not
  generating, not resetting, map and stage non-null. New = seed or map/stage
  pointer differs from before the reset, or generation was observed. Then the
  dict snapshot must differ from the previous map's and be identical across
  two reads 25 ms apart. Poll every 10 ms, 10 s timeout.

## Reset

- Virtual keyboard via `/dev/uinput` (python-evdev `UInput`), created once at
  daemon start so the compositor has registered it before first use.
- Holds the reset key (`KEY_Q`, the user's QuickReset binding; configurable in Nix) for
  `quick_reset_time + 0.05` s, read from
  `~/.config/unity3d/Ved/Megabonk/Saves/LocalDir/config.json`
  (`quick_reset_time`, fallback 1.0) at each toggle-on.
- **Focus guard:** before every key hold, `hyprctl activewindow -j` must report
  the game's pid (or class containing `megabonk`, case-insensitive). Otherwise
  stop rerolling.

## Nix layout

- `home/apps/bonk-reroll/bonk_reroll.py` — the script (Python 3, deps:
  `evdev`; rest stdlib).
- `home/apps/bonk-reroll/test_bonk_reroll.py` — unittest suite.
- `home/apps/bonk-reroll/default.nix` — home-manager module: builds the script
  as a `stdenvNoCC` derivation (python3 with `evdev`, `makeWrapper` passing
  `--config <store JSON>` holding the modes + reset key), runs the unittest
  suite in `installCheckPhase` so a failing test fails the system build, adds
  the package to `home.packages`. Imported from `home/apps/default.nix`.
- `home/desktop/hyprland/keybinds.nix` — `Mod+F5` → `bonk-reroll toggle`,
  `Mod+Shift+F5` → `bonk-reroll next-mode`.
- `system/default.nix` — `hardware.uinput.enable = true`.
- `system/users.nix` — add `uinput` group (NOT `input`: no reading real
  keyboards).

## Testing

- Unit tests (run in `installCheckPhase`, see Nix layout): mode evaluation (>=, `shady_moais` sum, missing counter
  treated as 0), dictionary walk + managed-string decoding against a fake
  memory buffer, map-ready state machine against scripted state sequences.
- Manual: launch via Steam with the launch option, confirm `bonk-reroll` is in
  the process tree, toggle with `Mod+F5`, verify rerolls stop and the game pauses
  on a matching map, and that rerolling stops on alt-tab.

## Out of scope

Kills/sec, rarity odds, chaos-tome tracking, overlays, recordings, Twitch,
auto-updating offsets.
