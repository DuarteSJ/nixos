# Launcher restyle — floating card that drops from the top

## Goal

Make the app launcher (`home/shell/quickshell/qml/Launcher.qml`) look like the
rest of the shell. Today it is the only surface with a thick (2 px) blue border,
a solid blue "Apps" chip and a solid blue selection fill, and it sits dead
centre on screen. Behaviour (search, ranking, keys, IPC) stays as it is.

## Placement

- Horizontally centred on the focused screen, anchored to the **top**, not
  `centerIn`. The card grows downward only as results change (today it grows
  up and down at once).
- Rest position: `Theme.barHeight + 12` px from the screen top while the bar
  is shown (`Shell.barShown`), `12` px when it is hidden (Super+B, focus
  mode). 12 is a local constant at the use site, like the other in-surface
  spacing.
- Width stays 600; row height, max 8 visible rows and list behaviour unchanged.

## Animation

- Open: the card starts fully above the screen edge (`y = -height`) and slides
  down to its rest position (~220 ms, `Easing.OutCubic`) while fading in.
- Close: slides back up past the edge and fades out; the layer surface stays
  visible until the slide finishes, then hides (no cut-off mid-animation).
- Height changes while open keep the existing 120 ms `OutCubic` behaviour.
- Replaces the current opacity + 0.97 scale pop.

## Frame

- Fill `Theme.bg`, corners `Theme.radius`.
- Border: 1 px `Theme.glassEdge` (the hairline the status panels and sliders
  already use) instead of 2 px `Theme.blue`.
- No drop shadow.

## Inside

- Search field: `Theme.glassFill` rounded box (radius 10, as today) with a
  search glyph in `Theme.iconFont` on the left in `Theme.muted`; the blue
  "Apps" chip goes. Placeholder "Search…" stays.
- Selected row: `Theme.glassFillStrong` rounded highlight plus a short
  vertical `Theme.accent` bar at its left edge. Text stays `Theme.fg` (name)
  and `Theme.subtle` (subtitle) whether selected or not; the name is still
  bold when selected.
- Icons, list spacing and the highlight move animation unchanged.

## Unchanged

Fuzzy scoring, launch-count ranking and its state file, keyboard handling
(Up/Down, Tab/Shift+Tab, Ctrl+J/K/N/P, Enter, Esc), click outside to close,
`launcher toggle` IPC and the Super+E bind.

## Verification

Live dev loop (no rebuild): build the quickshell config, run `qs -p <devdir>`
with the repo QML symlinked, toggle via `qs -p <devdir> ipc call launcher
toggle`, and record open/close with `wf-recorder` to check the drop and the
close slide. Check with the bar shown and hidden. Then `nixos-rebuild`.
