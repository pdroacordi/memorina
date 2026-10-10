---
id: bugs/wall-climb-leaves-the-world-over-the-cliff-chimneys-west-wall
type: bug
title: Wall climb carries Ivo over the top of orchard_cliff_chimney's west wall, out of every room, into an endless fall with no kill plane
status: resolved
severity: high
tags: [world-05, wind-orchards, out-of-bounds, softlock, wall-climb, chimney, kill-plane, camera]
related: [playtests/2026-10-10-traversal-orchards-caldera, bugs/the-orchard-arena-barrier-is-jumped-over-into-the-cliff-chimney, systems/world, systems/life-benches-death]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/rooms/wind_orchards/contents/orchard_cliff_chimney.room
  - scenes/characters/ivo/abilities/wall_mobility_component.gd
  - scenes/world/game.gd
---

## Summary

`WallMobilityComponent` refreshes the jump's coyote time and the double jump on every slide. Holding into a
wall and tapping jump therefore climbs any wall without limit. That is the intended "climb back up the chimney"
with wall climb. But the chimney's west wall (col 0, the world's west edge) stops at the room's top edge (y
-1536), and nothing lies above or west of it. Ivo climbs over it and drops into empty space west of the world.
He falls at 1000 px/s forever: no room catches him, no hazard or kill plane respawns him, and the camera
follows him into a blank grey frame.

## Symptom

HEAD 5062946, imported 00:23:06. Kit: double jump, wall climb, roll.
`tools/playtest/scripts/traverse_orchards_caldera_o8c_wall_climb_fall_shaft_past_overhang.json`:

```
t 1-9.6   hold left + jump every 0.55 s up col 0 from the floor (1888) to feet 758 (under the row-69 overhang)
t 9.7     let go, drift right 0.28 s, double jump, steer left: grabs col 1's face (feet 796 at t 10.15)
t 20.15   feet (-10835.9, -1384)      still on the wall
t 20.90   feet (-10855.1, -1581.6)    above the room's top (-1536), moving west of x -10880
t 22.15   feet (-11095.1, -1656.7)    outside every room; room stays orchard_cliff_chimney
t 39.15   feet (-14334.6, 15121.1)    still falling at 1000 px/s; camera centre (-14035, 14949); visible 1.00
```

Frames: `playtests/screenshots/2026-10-10-traversal-orchards-caldera/chimney_wall_climb_out_of_the_world.png`
(the last frame is Ivo alone in a flat grey void).

Holding into the west wall alone (`..._o8a_wall_climb_fall_shaft_west_wall.json`) stops under the overhang at
feet 758 and bobs there for as long as the input is held. The step-out-and-double-jump in `o8c` is what gets
past it. A player who learns that move then climbs straight out of the world at the top.

## Root cause

- **The room:** the top edge is open sky (`docs/maps/README.md`: "past the top is open sky"), and col 0 is
  the outermost wall of the westernmost room. With no room above or beside it, the open top is a hole in the
  world.
- **No out-of-bounds catch:** `Game` keeps the last room current while Ivo's body is outside every room
  (correct for a jump above a room's top), and nothing ends a fall that never lands.

## Fix

Suggested, both:
- **Level:** give the chimney (and the arena) a ceiling row, or extend col 0 above the climb so the top exit is
  only to the east. Any room at the world's edge with an open top needs the same check.
- **Engine safety net:** treat "body outside every room and below the lowest room bottom", or "outside every
  room for more than N s", as a hazard fall. It should respawn at the last safe ground, as water does
  (`systems/life-benches-death`). Then no out-of-bounds bug can soft-lock a save.

## Prevention

- A `room_files_test` check: a room at the edge of the world grid must not leave its top row open over a wall
  column that touches its outer edge.
- A unit test for the out-of-bounds hazard.

## Resolution (2026-10-10, re-verified)

The chimney's row 0 is now solid, and `Game` runs the hazard beat whenever Ivo has left every room (`_lost`).
Working tree on 5062946 with the coordinator's fixes, `--import` at 01:27:51; nothing changed after it.
- **The same climb** (`traverse_orchards_caldera_o8c_wall_climb_fall_shaft_past_overhang.json`) gets past the
  overhang as before. Under the new ceiling it bobs at feet -1438..-1450 for the rest of the run (t 20.9-39.4).
  No fade, and Ivo never leaves the room.
- **The way back up with wall climb works**
  (`traverse_orchards_caldera_rv_o9_wall_climb_chimney_up_and_out_to_arena.json`). At the top he jumps off the
  slide with right held and lands on the top step (-10567, -1184). From there a 64 px hop leads to the top
  floor and the arena.
- **New problem from the safety net:** it also fires on a plain double jump above any open room top.
  `bugs/the-out-of-room-safety-net-fires-on-a-double-jump-above-an-open-room-top`.
