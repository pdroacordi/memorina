---
id: systems/input
type: system
title: Input: actions, gamepad layout, the three event readers and device glyphs
status: active
tags: [input, gamepad, glyphs, keybindings, menu, pause]
related: [systems/map, systems/notebook, architecture/character-controller-input-split, architecture/pause-menu-worldfreeze-reuse, systems/screens, gotchas/a-stick-is-pressed-on-every-motion-event, gotchas/gui-focus-moves-once-per-stick-tilt, gotchas/a-menu-press-reaches-the-last-node-first, bugs/player-input-edge-state-goes-stale-across-a-pause-menu]
created: 2026-10-02
updated: 2026-10-06
source_files:
  - scenes/characters/ivo/player_input.gd
  - scenes/ui/menu/menu_input.gd
  - globals/input_device.gd
  - project.godot
---

# Input: actions, gamepad layout, the three event readers and device glyphs

## Actions (`project.godot`)

| Action | Keyboard | Pad | Deadzone |
|---|---|---|---|
| `move_left` / `move_right` | arrows | left stick X, D-pad | 0.2 |
| `look_up` / `look_down` | Up / Down | left stick Y, D-pad | 0.5 |
| `jump` | Z | A (0) | 0.2 |
| `attack` | X | X (2) | 0.2 |
| `roll` | Shift | B (1) | 0.2 |
| `draw_memorina` | C | RB (10) | 0.2 |
| `note_up` / `note_down` / `note_left` / `note_right` | arrows, WASD | Y / A / X / B | 0.2 |
| `pause` | Esc | Start (6) | 0.2 |
| `notebook` | E | Back/Select (4) | 0.2 |
| `map` | M | LB (9) | 0.2 |
| `map_zoom_in` / `map_zoom_out` | Z / X | A (0) / X (2) | 0.2 |
| `ui_accept` (override) | Enter, keypad Enter, Space, Z | A (0) | 0.5 |
| `ui_cancel` (override) | Esc | B (1) | 0.5 |
| `debug_learn_song` / `debug_trials` | F9 / F10 | none | debug builds |

- The gameplay pad layout is the user's (2026-10-01). While the instrument is out the face buttons are its notes, and `move_axis` / `_try_jump` / `_try_roll` / `_try_attack` ignore input; a jump, roll or attack press that was a note is dropped (`Player._as_move`), never buffered.
- **`ui_accept` and `ui_cancel` are overridden** because Godot 4.7's built-ins carry no pad binding (measured: `ui_accept` is Enter, keypad Enter and Space; `ui_cancel` is Escape). The override copies those keys and adds Z, pad A and pad B. Keyboard X is not in `ui_cancel`.
- User decisions, 2026-10-02: pad "Start / Select / LB" (Start = pause, Select = notebook, LB = map); "A confirm, B back".
- `notebook` is live (UI-03, `systems/notebook`): E / Select toggle it, Esc and B close it, left / right turn its pages and up / down move between entries.
- `map`, `map_zoom_in` and `map_zoom_out` are live (UI-04, `systems/map`). Z / X and pad A / X zoom only while the map is open; `Screens` consumes them only then, so otherwise they jump and attack.

## The three InputEvent readers

Only these three nodes read `InputEvent`s; the `verify-gates` input scan excludes exactly their files.

1. **`PlayerInput`** (pausable, a `CharacterController`): gameplay presses as signals, axes as properties.
   - `look_down_pressed` is an edge (`_down_held`): a stick reports pressed on every motion past its deadzone (`gotchas/a-stick-is-pressed-on-every-motion-event`).
   - `_jump_held` tracks the jump for the cut.
   - **Resync.** On `NOTIFICATION_UNPAUSED` and `NOTIFICATION_ENABLED`, `resync(jump_held, down_held)` re-reads both from `Input`: a jump released while it received no events emits `jump_canceled`, and down held through a menu is not a new press (`bugs/player-input-edge-state-goes-stale-across-a-pause-menu`).
   - **`blocked`** (set by `Player.block_input` / `unblock_input` while the map is open): the node is DISABLED, so `_input` does not run, and `direction` and `look_direction` read 0. Clearing it re-enables the node, which resyncs. `Player.block_input` also drops the jump, roll, attack (including a combo press) and draw buffers and any pending sit or stand, so a press made just before the open never acts under the map.
2. **`MenuInput`** (`scenes/ui/menu/menu_input.gd`, under the ALWAYS `Screens` root):
   - Emits at most one signal per event, in precedence `pause_pressed` > `notebook_pressed` > `map_pressed` > `zoom_pressed(direction)` > `back_pressed` (`ui_cancel`) > `page_pressed(direction)`. Esc is both `pause` and `ui_cancel`, so Esc is only `pause_pressed`.
   - `page_pressed` is the edge of `ui_left` / `ui_right` (`_left_held` / `_right_held`); the notebook turns its pages on it. `pan: Vector2` is polled from `Input.get_vector` over `ui_*`.
   - The arrows and the left stick are both `ui_*` and movement. The map therefore ignores each pan axis already held when it opens until that axis reads zero (`MapScreen.pan_held`, `bugs/a-direction-held-when-the-map-opens-pans-it-off-ivo`).
3. **`InputDevice`** (autoload): remembers the last device as an `Enums.GlyphSet`, using `PlayerInput.glyph_set_for`.
   - It listens on `get_tree().root.window_input`, which fires before dispatch. So a press a menu marks handled (Esc, Start, B) and a press made while paused still switch the prompts.
   - A stick counts only past `STICK_THRESHOLD` (0.5), so drift never flips the prompts. A motion event is the pad as much as a button is.

## On the title

The title has its own `MenuInput` (`scenes/ui/title/title.tscn`). Esc arrives as `pause_pressed` and pad B as `back_pressed`; the title treats both as back: they close a confirmation, then leave the slot screen. Nothing opens or quits on them.

## Focus navigation

- The engine's `ui_*` focus navigation moves once per stick tilt through `Input.parse_input_event` (measured in 4.7.2, `gotchas/gui-focus-moves-once-per-stick-tilt`), so menus keep the stick on `ui_up` / `ui_down`.
- `_input` reaches the last node in the tree first. `ScreenLayer` stays after `World` in `game.tscn`, so `MenuInput` sees a press before `PlayerInput` (`gotchas/a-menu-press-reaches-the-last-node-first`).

## Prompts

`KeyGlyph` draws an action's binding for the current device from `InputGlyphs` (`resources/ui/input/`, built by `tools/ui/build_input_glyphs.gd` from `assets/sprites/hud/input/`). A key with no symbol of its own (Z, Shift, C) is the blank key with its name.
