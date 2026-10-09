---
id: bugs/the-tavern-upper-floor-has-no-way-down
type: bug
title: The tavern's upper floor is a softlock, because Ivo cannot drop through a one-way ledge
status: open
severity: high
tags: [rooms, softlock, one-way-ledge, interior, tavern, world-05, base-kit]
related: [playtests/2026-10-09-traversal-opening, systems/rooms, architecture/doors-and-interiors]
created: 2026-10-09
updated: 2026-10-09
source_files:
  - scenes/world/rooms/home_village/contents/village_tavern.room
  - scenes/characters/ivo/player.gd
  - docs/maps/README.md
---

## Summary

`village_tavern.room` row 13 is the upper floor: earth at cols 0-17 and 31-39, and the one-way span `=` at
cols 18-30 that Ivo jumps up through. Nothing in Ivo's controls drops him through a one-way ledge. Once
upstairs he cannot get down, and the tavern's only door is on the lower floor.

## Symptom

`tools/playtest/scripts/traverse_opening_m_tavern_two_floors.json`, build ba88e1d. Ivo jumps from the
lower floor (y 12672) to the 4-cell ledge (12544), then to the upper floor (12416), and walks its whole
length (x 1753..2648). On the span at x 2349:
- a `look_down` tap, `look_down` held with a jump, and `look_down` held for 1.2 s each left him at y 12416;
- the down+jump only made a normal jump that landed back on the span.

The only way out is quit to title. Screenshot: `playtests/screenshots/2026-10-09-traversal-opening/tavern_upper_floor_no_way_down.png`.

## Root cause

The legend promises "jump up through it, stand on it, drop through it" (`docs/maps/README.md`, `=`), but
no drop-through exists. `player.gd` and `player_input.gd` read `look_down` only for sitting, climbing and
the pogo attack. Every other `=` ledge in the opening (square roofs, lane, bakery, elder loft, fields
roof, tavern ledge at row 17) has an open end Ivo can walk off, so the gap went unnoticed. The tavern's
upper floor is the only one that spans wall to wall.

## Fix

Not fixed. Either:
- implement a drop-through (down + jump on a one-way tile is the usual binding; a `systems/input` decision); or
- give the tavern's upper floor an edge to walk off, for example open cols 31-32 of row 13 next to the span.

The legend line should match whichever is chosen.

## Prevention

A room validator rule: every walkable region bounded only by `=` and walls must have a way down.
Alternatively, the room reachability tests could treat `=` as one-way and check that every door can be
reached from every spot.

## Resolution (2026-10-09)

A two-cell stairwell at the east end of the upper floor (row 13, cols 31-32) lets Ivo walk off it; there is still no drop-through for `=` (the legend's wording is wrong about that, a roadmap row).
