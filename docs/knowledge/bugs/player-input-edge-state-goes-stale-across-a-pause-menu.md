---
id: bugs/player-input-edge-state-goes-stale-across-a-pause-menu
type: bug
title: PlayerInput misses every event while a menu holds the tree, so a jump release is lost and a held stick sits Ivo after the menu closes
status: fixed
severity: low
tags: [input, pause, menu, player-input, edge, jump, sit, stick]
related: [playtests/2026-10-02-pause-menu, gotchas/a-stick-is-pressed-on-every-motion-event, gotchas/a-menu-press-reaches-the-last-node-first, bugs/a-down-press-made-while-sinking-sits-ivo-on-respawn, architecture/pause-menu-worldfreeze-reuse]
created: 2026-10-02
updated: 2026-10-02
source_files:
  - scenes/characters/ivo/player_input.gd
  - scenes/ui/screens/screens.gd
---

## Summary

`PlayerInput` is pausable and builds two things from event history: the jump cut (the
release in `_input`, player_input.gd:67) and the down edge (`_down_held`,
player_input.gd:76-80). While the pause menu holds the tree it receives no events at all,
so whatever changed during the menu is never seen. Measured in Godot 4.7.2: a paused
node's `_input` is skipped, not queued.

## Symptom

Reasoned from the code plus the measured dispatch, then reproduced in game for both
(playtests/2026-10-02-pause-menu, below).

1. **Lost jump cut.** Ivo jumps with the jump button held, the player pauses (Esc or
   Start), releases jump inside the menu, and resumes. `jump_canceled` never fires, so
   `JumpComponent.cut_jump` never runs and a short hop becomes a full-height jump.
2. **Unchosen sit.** Ivo stands beside a bench. In the menu the player tilts the left
   stick down (ui_down moves focus to "Quit game") and closes the menu with B or Start
   while the stick is still down. `_down_held` is still false from before the pause, so
   the first stick motion event after the thaw is a new edge. `look_down_pressed` sets
   `_sit_requested` and Ivo sits, rests and commits the save. The reverse also happens:
   down held at pause and released in the menu leaves `_down_held` true, and the first
   real down press after the menu is ignored.

**Reproduced 2026-10-02** with real key events (`tools/playtest/scripts/pause_menu_roll_air.json`
and `pause_menu_bench_down_release.json`, winter and summer trials):

- Z pressed, Esc 0.15 s into the rise, Z released inside the menu, Esc: the apex is y 5849.2,
  the same as a held full jump (5848.7). An unpaused tap released at the same 0.15 s peaks at
  5911.5. The release in the menu cost 62 px of cut.
- Seated on the summer bench with Down held, Esc, Down released inside the menu, Esc, Z to
  stand: the first Down press afterwards does nothing (`sit=false`); the second sits him. The
  same stand-and-press without the menu sits on the first press.
  (`playtests/screenshots/2026-10-02-pause-menu/bench_down_lost.png`)

- Standing beside the summer bench: Start, left stick down to 1.0 (focus moves to Quit game),
  B with the stick still down, then one motion event at 0.97: Ivo sits (`sit=true`) without
  any down press made in the world (`pause_menu_bench_stick_held.json`).

## Root cause

Edge and release state is derived from events, and a pausable reader does not receive
events while the tree is paused. Before UI-02 the only freeze was a performance, with
Ivo standing still and the instrument out. The pause menu can freeze him at any moment,
and its navigation uses the same stick.

## Fix

Fixed 2026-10-02 (`scenes/characters/ivo/player_input.gd`):
- `PlayerInput._jump_held` tracks the jump from its press and release events.
- `_notification` handles `NOTIFICATION_UNPAUSED` and `NOTIFICATION_ENABLED` (the room-transition re-enable). It calls `resync(Input.is_action_pressed("jump"), Input.is_action_pressed("look_down"))`.
- `resync` is pure: it emits `jump_canceled` if a held jump is no longer held, then adopts both held states. Three tests cover it in `tests/scenes/characters/ivo/player_input_test.gd`.

Measured with the playtest timelines (windowed, 4.7.2):
- `pause_menu_roll_air.json`, jump released in the menu: the apex is y 5912.3, against 5911.5 for an unpaused tap (5849.2 before the fix, a full jump).
- `pause_menu_bench_down_release.json`: the first Down after resuming sits him (`sit=true`; before, it did nothing).
- `pause_menu_bench_stick_held.json`: no phantom sit after the stick-down close (`sit=false`).

## Prevention

Any input node that tracks an edge or waits for a release must re-sync whenever it was
not receiving events: on unpause, on re-enable after `PROCESS_MODE_DISABLED` (room
transitions), and on respawn.
