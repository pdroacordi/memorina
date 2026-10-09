---
id: bugs/walking-across-a-room-seam-fades-back-and-forth
type: bug
title: At a seam between two abutting rooms the walk-in fade swings back and forth, and forever if Ivo stands across a horizontal seam
status: open
severity: high
tags: [rooms, room-transition, fade, physics, area2d, seam, softlock, world-05]
related: [playtests/2026-10-09-traversal-opening, bugs/a-teleported-ivo-enters-the-room-he-left, gotchas/a-teleported-kinematic-body-overlaps-from-its-old-place-for-one-step, systems/rooms]
created: 2026-10-09
updated: 2026-10-09
source_files:
  - scenes/world/game.gd
  - scenes/world/rooms/room.gd
---

## Summary

Since WORLD-05 every room is a macro rectangle that shares an edge with its neighbour. While Ivo's
capsule overlaps two rooms, `Game` fades from one to the other and back, with one physics step of
movement per ~1 s fade.
- **Vertical seams:** walking through costs ~7 fades and ~7 s at every seam tested.
- **Horizontal seams:** a floor less than 54 px (Ivo's height) below a seam never ends the loop. A jump
  whose head crosses a seam crawls through its arc at one step per fade. Both are softlocks.

## Symptom

Build ba88e1d, `tools/playtest/scripts/traverse_opening_*.json`.

**Walking through a vertical seam** (`traverse_opening_b_square_to_fields`, `move_right` held from
village_square (1040, 288)):

```
t=6.00  pos=(1916.3,288) fade=0.20 pmode=4               (room village_square)
t=6.50  pos=(1916.3,288) fade=0.82 room=village_mill
t=7.50  pos=(1919.5,288) fade=0.88 room=village_square
t=8.50  pos=(1922.7,288) fade=0.93 room=village_mill
...                                                       (4 more swaps, +3.2 px each)
t=13.25 pos=(1964.3,288) fade=0.00 pmode=0               (free)
```

The same thing happens at square/mill, mill/gate_east, gate_east/threshold_fields,
fields/bridge, bridge/wayshrine, wayshrine/frost_shore, shore/cliffs, cliffs/lighthouse_base and
square/lane_west (walking west). Each seam costs 6-7 swaps.

**Standing across a horizontal seam: softlock** (`traverse_opening_w2_well_beam_loop`). Ivo falls into
the square's well and lands on village_cistern's top beam (row 1, y 416). His capsule spans y 362..416,
across the square/cistern seam at y 384. From t 1.5 to 30.0 `room` alternates village_square /
village_cistern every 0.5-1 s with `pmode=4`. Eighteen jump presses (t 20-29) never move him.

The cistern's only way back up is from that beam: beam row 5 (y 544) is 256 px below the square's
floor. So any fall into the well is a softlock today.

**A jump across a horizontal seam** (`traverse_opening_x_mill_river_trail`). A straight jump from the
mill's river trail (3042, 160) puts his head above y 0, into lake_waterfall_path. From t 5.1 to 28 he
hangs at y 48 → 37 → 41, mid-arc, still alternating rooms when the run ends.

Screenshots: `seam_1_fading_into_mill.png`, `seam_2_back_in_square.png`, `well_beam_loop_*.png` in
`playtests/screenshots/2026-10-09-traversal-opening/`.

## Root cause

`Game._on_player_entered_room` (game.gd:59) sets Ivo's `process_mode` to DISABLED for the fade and back
to INHERIT after it. A disabled body leaves the physics space. When it is re-enabled it enters again,
and every `Room` Area2D it overlaps reports `body_entered`. When his capsule (radius 11, height 54)
overlaps two rooms, the other one is not `_current_room` and starts a new transition. Each cycle allows
one physics step. If that step does not take his capsule out of the old room, the cycle repeats.

The old world's rooms did not abut edge to edge, so the overlap at re-entry did not arise there.

## Fix

Not fixed. Options, for the implementer:
- Accept a `room_entered` only when the room contains Ivo's position (`room.get_bounds().has_point(
  _player.global_position)`, the test `_room_at` already uses). One point is in exactly one room, so
  no overlap can swap rooms back. For the two floors found here, the feet and the capsule's centre
  (feet - 27) fall in the same room: the cistern beam (416 / 389) is in village_cistern, and the
  mill's upper slab (32 / 5) is in village_mill.
- Or keep Ivo in the physics space during the fade (stop his processing without removing the body).

## Prevention

Two walk-in tests: one that holds a direction across two abutting rooms and asserts exactly one
`room_changed`, and one that stands a body across a horizontal seam for a second.

## Resolution (2026-10-09)

`Game` keeps the room that contains Ivo's feet (`_physics_process` + a guard in `_on_player_entered_room`); measured: one change at the square/mill seam and no swap back (`tools/playtest/scripts/seam_cross.json`).
