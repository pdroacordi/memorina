---
id: bugs/the-root-caves-well-is-climbable-without-enraizar
type: bug
title: A running double jump from the root caves' shelf block reaches the new one-way at the shaft's top, so the well is climbable without Enraizar
status: resolved
severity: medium
tags: [rooms, level-design, spring-woods, world-05, gate, double-jump, root]
related: [playtests/2026-10-09-traversal-woods-lake, systems/roots-and-climbing, systems/rooms]
created: 2026-10-09
updated: 2026-10-11
source_files:
  - scenes/world/rooms/spring_woods/contents/woods_root_caves.room
---

## Summary

The re-verification edit added a one-way at woods_root_caves row 0, cols 28-29 (world x -3584..-3520,
y 384). It gives the Enraizar rungs a ledge to end on. But a double jump with a run-up from the shelf block
east of the well (cols 32-38, top y 608) peaks at y 367-371, which is above that one-way. A double-jump
player can climb out without roots. The file's own comment says "Espacial 2: roots climb to the row-0
ledge, 10 rows up".

## Symptom

Uncommitted WORLD-05 work on ea47690. `"skills": [0]` (double jump), no songs.

- **From the well floor** (y 704): the double jump peaks at y 463.6. Blocked, as intended
  (`traverse_woods_lake_i3_rv_caves_well_climb_and_jump_out.json`).
- **The shelf block is one single jump** (96 px) from the well floor, through the shelf exit (col 32,
  rows 4-6).
- **Running double jump from the block** (`traverse_woods_lake_i6_rv_caves_block_running_double_jump_{174,180,186}.json`):
  start at (-3300, 600), hold left, double jump (0.3 s, 0.1 s gap, 0.35 s) at t 1.74, 1.80 and 1.86.

| Take-off t | Peak y | Result |
|---|---|---|
| 1.74 | 473.3 | first jump bumps the col 32 ceiling (row 3, underside y 512) |
| 1.80 | 366.7 | lands on the one-way (-3571.9, 384) |
| 1.86 | 371.4 | lands on the one-way (-3571.9, 384) |

- **Then one jump with left held** (`..._i7_rv_caves_no_root_double_jump_skip.json`) lands on woods_deep's
  floor at (-3678.4, 288). This was re-run on the region-cut code with the same result.

## Impact

- The well's "roots only" climb (design 02 section 8, Espacial 2) is beaten by the double jump.
- Nothing further is skipped today. The exit is woods_deep's closed pocket west of the pit (cols 24-32,
  y 288). Leaving it eastward needs the Enraizar bridge: the corridor over the pit has 64 px of headroom,
  so no jump fits.
- A player who reaches the caves without Enraizar some other way would also escape this way. And if the
  pocket ever gains an exit, this becomes a real gate skip.

## Fix

Not fixed. Any one of:
- raise the shelf block's top by a row (y 576), so a double jump from it peaks below 384;
- or give col 32 rows 1-3 an overhang that caps a jump from the block (it already caps one that takes
  off at the block's edge);
- or move the one-way up into woods_deep's shaft, if the rungs can reach it.

## Prevention

`room_files_test` cannot see this. A reach check per gate (the highest point a kit reaches from each
standable cell) would.

## Resolution (2026-10-10)

`woods_root_caves.room`: the shelf block is two rows lower (rows 9-10, top y 672), the col-32 exit is
rows 6-8, and col 32 is solid in rows 0-5, so the roots grow in one run. Re-checked on the uncommitted
tree, imported 23:58:40:
- **Running double jump from the shelf**
  (`tools/playtest/scripts/traverse_woods_lake_i6b_rv2_caves_shelf_running_double_jump_{170,176,182,188,194,200,206,212}.json`):
  the best peak is y 431.3, 47 px under the one-way (384). He falls back to the well floor in all 8 timings.
- **Roots** (`..._i11_rv2_caves_root_climb_one_run.json`): one continuous climb from 704 to 426. Jump off
  the top rung (peak 299.6) onto the ledge, then one jump to woods_deep's floor (-3699.9, 288).
- **Well exit and east chamber** (`..._x1_rv2_caves_well_to_shelf_and_east.json`): the shelf (672) is
  reached from the well floor, and walking east drops onto the chamber's block at (-3068.6, 768).

## Revision (2026-10-11)

The uncommitted WORLD-25 rework removed the row-0 one-way, which this resolution relies on ("Jump off the top rung (peak 299.6) onto the ledge"). The double-jump skip stays closed, because the shelf is unchanged. But the roots no longer end on a ledge: the same jump now falls back to the well floor. See `bugs/the-root-caves-roots-end-short-of-woods-deep-without-the-row-0-ledge`.
