---
id: bugs/the-orchard-arena-barrier-is-jumped-over-into-the-cliff-chimney
type: bug
title: The wall-climb barrier in orchard_arena is a step - a double jump from its top clears the arena's west wall, and the chimney below has no way out without wall climb
status: resolved
severity: high
tags: [world-05, wind-orchards, gate, softlock, barrier, double-jump, chimney, wall-climb, rooms]
related: [playtests/2026-10-10-traversal-orchards-caldera, bugs/wall-climb-leaves-the-world-over-the-cliff-chimneys-west-wall, bugs/a-redoma-first-player-is-trapped-in-the-summer-caldera, systems/world, systems/rooms]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/rooms/wind_orchards/contents/orchard_arena.room
  - scenes/world/rooms/wind_orchards/contents/orchard_cliff_chimney.room
---

## Summary

`orchard_arena`'s barrier (`X` at col 1, `requires` `has_wall_climb.tres`) is meant to keep anyone without wall
climb out of the cliff chimney (`systems/world`, known limits). It does not: the 96 px barrier is a step. From
its top a double jump clears the arena's west wall, which ends at the room's top edge with no ceiling. Ivo
lands on the chimney's top floor, walks off its step and falls 3 100 px to the chimney floor. Down there, the
only exit is the pocket over col 10, 352 px up. The double jump reaches 241 px of that. No hazard can kill
him, so the only way out is to reload.

## Symptom

HEAD 5062946, imported 00:23:06. Kit: double jump and roll, no wall climb (`skills [0, 2]`).

`tools/playtest/scripts/traverse_orchards_caldera_o3_barrier_top_double_jump_into_chimney_no_wall_climb.json`:

```
t 1.30  jump, left held        stopped by the barrier's face at x -10163.9
t 2.20  feet (-10193.6, -1344)  standing on the barrier top (96 px above the floor)
t 2.40  double jump, left held  peak feet -1585.9 at x -10253 (the arena wall top is -1536)
t 3.80  room=orchard_cliff_chimney (glide)
t 4.20  feet (-10442.1, -1248)  on the chimney's top floor, west of the barrier
```

`..._o3b_chimney_fall_no_wall_climb_stuck.json` (from that floor's step, x -10600):

```
t 5.20  feet (-10750.3, 1887.9)  chimney floor, hp 3 (no fall damage)
climb shaft (x -10570), three double jumps: peak feet 1647.6 each time; col 10's top is 1536
fall shaft (x -10836): peak 1647.6
```

Frames: `playtests/screenshots/2026-10-10-traversal-orchards-caldera/arena_barrier_double_jump_over_the_wall.png`
and `chimney_floor_no_wall_climb_stuck.png`.

## Root cause

Level geometry.
- **Arena:** the opening at col 0 is rows 5-8 (128 px). The barrier fills rows 6-8, which leaves row 5 open
  above it. The wall over the opening (col 0, rows 0-4) stops at the room's top edge (y -1536), and no room
  lies above.
- **The reach:** the barrier top is at -1344, so the wall top is 192 px above it. The double jump reaches
  270 px.
- **Chimney:** its east wall (col 19, rows 0-4) has the same shape, so the far side is open too.

## Impact

- A player who reaches the arena before the autumn guardian's gift (the main path leads there) can lock their
  save.
- The likely sequence is "hop on the purple block, jump again, fall down the hole".
- Without a bench in the chimney nothing is saved there. Still, the session ends unless they find
  quit-to-title.

## Fix

Suggested, either:
- Make the barrier meet a lintel: make arena row 5 solid at cols 0-1 (and chimney row 5 at col 19), so nothing
  stands on the barrier. Close the arena's top over cols 0-2 (or the whole room) up to the room's top row.
  The floor alone is 288 px below the wall top, out of the double jump's reach.
- Or move the gate to the chimney's top floor, under a ceiling. The chimney's rows 0-8 over cols 12-19 are
  open sky today.

Pair it with `bugs/wall-climb-leaves-the-world-over-the-cliff-chimneys-west-wall`: both come from walls that end
at an open room top.

## Prevention

A reachability check for barrier gates: from the barrier top and from any floor within 270 px, the far side
must not be reachable over the room's top edge. More generally, `room_files_test` could flag a wall column
that ends at row 0 of a room with no room above it.

## Resolution (2026-10-10, re-verified)

The arena gained a stone lintel over cols 0-2 (rows 0-4) and an overhang at (3, 0). Working tree on 5062946 with the coordinator's fixes, `--import` at 01:27:51; nothing changed after it.

`tools/playtest/scripts/traverse_orchards_caldera_rv_a1_arena_barrier_and_lintel_no_wall_climb.json` (no wall climb):
- A 0.45 s jump at the barrier never stands on it. No grounded sample above the floor.
- Double jumps at the barrier's face, including one with a late second press, peak at feet -1450: the head
  meets the overhang's underside (-1504).
- Ivo never gets west of x -10164, the barrier's face.

The wall-climb route through the open barrier and down the chimney still works:
`traverse_orchards_caldera_o4_wall_climb_arena_chimney_to_caldera.json` re-run, cut into caldera_chimney_base
at feet x -10214.9.
