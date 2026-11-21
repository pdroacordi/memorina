---
id: bugs/guardian-region-props-placed-inside-ground-cells-draw-nowhere
type: bug
title: Three guardian-region props stand inside a ground block, so the z 0 ground hides all or nearly all of them
status: fixed
severity: low
tags: [props, world-15, world-16, world-17, placement, draw-order, prop-grounding-test]
related: [systems/props, systems/rooms, bugs/cut-props-left-a-transparent-bottom-row-so-props-floated]
created: 2026-11-20
updated: 2026-11-20
source_files:
  - scenes/world/rooms/summer_caldera/contents/caldera_dry_moat_contents.tscn
  - scenes/world/rooms/summer_caldera/contents/caldera_long_corridor_contents.tscn
  - scenes/world/rooms/wind_orchards/contents/orchard_terraces_contents.tscn
  - tests/scenes/world/environment/props/prop_grounding_test.gd
---

## Summary

Props are z -10 and ground cells are z 0, so a prop whose foot is on the floor *under* a one- or two-cell block
draws behind the block. Three WORLD-15..17 placements are hidden this way, and no test checks a placement
against its `.room`.

## Symptom

Status: open (WORLD-15..17 review, 2026-11-20; measured by projecting frame 0 of each prop onto its room's
`[grid]`).
- `caldera_dry_moat_contents.tscn:28`, `Shards` at (1700, 288): the floor under cols 52-54 is at y 256 (row 8 is
  `SSS`); the 32x10 shards sit at y 278..288 inside the block. 100% hidden.
- `caldera_long_corridor_contents.tscn:42`, `Rubble` at (1000, 288): row 8 cols 30-35 is `SSSSSS`; the 56x20
  rubble at x 972..1028, y 268..288 is inside it. 100% hidden.
- `orchard_terraces_contents.tscn:51`, `YoungTree` at (1150, 672): its trunk stands on row 21 inside the stone
  block at cols 35-38, rows 19-20 (y 608..672). 94% hidden; only a fringe of leaves shows over the block, reading
  as a bush growing out of stone.

## Root cause

Positions were set on the room's lowest floor line (y 288 / y 672) without checking for a block on that
column. `prop_grounding_test` only checks a prop scene's own art (opaque bottom row on its origin); it never
reads a contents scene or a `.room`. The board's step 4 ("`prop_grounding_test` checks every grounded prop
stands on a ground cell") claims more than the test does.

## Fix

**Applied.** Fixed 2026-11-20 before the WORLD-15..17 commit: `Shards` moved to (1580, 288) on the rim, `Rubble` onto the corridor shelf's top (1000, 256), `YoungTree` to (900, 672) clear of the block (the haystack and hay bale beside it moved east too). Prevention: `tests/scenes/world/environment/props/region_prop_placement_test.gd` fails any grounded prop in the three regions whose origin is not on a ground cell's top or whose foot is inside the ground (`NOT_ON_GROUND` lists the wall and back-wall props, each with a reason).


Not fixed. Move each to the block's top (y 256 for the two caldera props, y 608 for the tree, which then stands
on stone: prefer moving it west of x 1120 onto earth) or off the block.

## Prevention

Add a placement case to `prop_grounding_test`: for every `Props` child of every contents scene in the covered
regions whose scene is grounded (not in `HUNG`), the cell under its origin is ground, ledge or water, the cell
above it is not ground, and at most a set share (say 25%) of its opaque frame-0 pixels lies in ground cells.
