---
id: bugs/the-fishing-village-well-has-no-way-out
type: bug
title: Falling into lake_fishing_village's well mouth traps Ivo on lake_well's one-way; only death gets him out
status: resolved
severity: high
tags: [rooms, softlock, frozen-lake, world-05, level-design]
related: [playtests/2026-10-09-traversal-woods-lake, bugs/a-jump-across-a-horizontal-seam-loses-its-height-in-the-fade, playtests/2026-10-09-traversal-opening]
created: 2026-10-09
updated: 2026-10-09
source_files:
  - scenes/world/rooms/frozen_lake/contents/lake_fishing_village.room
  - scenes/world/rooms/frozen_lake/contents/lake_well.room
---

## Summary

lake_fishing_village's well mouth is 4 cells wide (cols 28-31, x 1536..1664) with a 1-cell stone curb
on each side (cols 27 and 32, top y -1664). It drops 128 px into lake_well onto a one-way (row 1,
x 1536..1664, y -1504). From the one-way the curbs are 160 px up. Ivo's jump is 143 px, and every
attempt also crosses the seam at y -1536 and is cut by the fade (peak y -1574). lake_well has no other
exit: its chamber is closed, and its lower room is reached only through the water column (a hazard). A
base-kit player who falls in can only leave by dying in the water, and the bench he respawns at may be
far behind.

## Symptom

Build 6fa077a, base kit (`tools/playtest/scripts/traverse_woods_lake_p_fishing_village_well_fall_and_escape.json`).
- A short hop from the floor at x 1708 onto the east curb carries Ivo over it into the mouth. He lands
  on the one-way at (1591, -1504).
- Four escape jumps, straight with apex steering and held from take-off, both directions: each peaks at
  y -1574 (two fades each), and he is back on the one-way at (1548, -1504).
- The intended crossing works: a running jump from x 1708 with left held clears the mouth and lands
  at x ~1440 (`..._q_fishing_village_well_jump_to_shore.json`).

This is the same pattern as village_square's well (`playtests/2026-10-09-traversal-opening`).

## Suggested fix

Any one of:
- lower the one-way by one row, or add a second one-way step in lake_well rows 2-4 beside the mouth,
  so the curb (160 px) is reachable in two jumps;
- drop the curbs, so the floor (-1632, 128 px) is the exit height, and fix the seam-fade cut;
- cover the mouth with a grate until the well's song (Redoma) is owned.

## Resolution (2026-10-09)

Fixed in `lake_fishing_village.room`: a two-cell notch in the mouth's west wall (cols 26-27, floor y
-1568), with the west curb moved to col 25. The seam fade that cut every jump is also gone. Re-verified
(`playtests/2026-10-09-traversal-woods-lake`, Re-verification), base kit:
- **Out to the west** (`tools/playtest/scripts/traverse_woods_lake_p2_rv_fishing_village_well_fall_and_climb_out.json`):
  the one-way (-1504) → notch (-1568) with a 0.4 s jump, left held → over the west curb to the floor
  (1389.5, -1632) with an apex-steered 0.4 s jump. 4 of 4.
- **Out to the east** (`..._p3_rv_fishing_village_well_west_to_east_held.json`): from the notch, a 0.45 s
  jump with right held clears the east curb (x 1664, top -1664) and lands on the curb or the floor
  beyond. 4 of 4.

Side effect (low): the mouth plus the notch is 192 px wide, so it can no longer be jumped over.
`..._q_fishing_village_well_jump_to_shore.json` now lands in the notch (1484, -1568). Crossing the village
always means dropping into the notch and jumping out.
