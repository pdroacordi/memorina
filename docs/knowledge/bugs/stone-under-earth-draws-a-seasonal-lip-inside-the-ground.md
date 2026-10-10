---
id: bugs/stone-under-earth-draws-a-seasonal-lip-inside-the-ground
type: bug
title: Stone directly under earth draws its exposed-top tile, so a grass/leaf/snow lip and rounded corners show inside solid ground (118 cells, 10 rooms)
status: active
severity: medium
tags: [world-07, dual-grid, tiles, underlay, corner-mask, stone, earth, aesthetics]
related: [playtests/2026-10-10-world07-legacy-tiles, bugs/earth-over-stone-draws-the-boundary-half-a-cell-low, architecture/biome-tilesets, bugs/an-earth-cell-boxed-in-by-stone-grows-a-corner-tuft]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/rooms/maps/ground_autotile.gd
  - scenes/world/rooms/maps/room_tile_resolver.gd
---

## Summary

Where an earth cell (`#`) sits directly on a stone cell (`S`), the stone layer treats the earth
above it as air and draws m 12, the exposed top. Its seasonal lip and rounded top corners draw
over the earth fill, so a second grass line runs through solid ground at every earth-on-stone
seam. Before WORLD-07 the stone under earth had N solid and drew plain fill.

## Symptom

Seen on the uncommitted WORLD-07 tree, 2026-10-10 (playtest `2026-10-10-world07-legacy-tiles`):

- orchard_terraces, at the bench (-4784, -1248): every earth-capped stone pillar (`####` on `SSSS`)
  shows a leaf-litter lip 32 px under its real top.
- orchard_leaf_path (-8300, -1248): the same under the long earth slab.
- woods_deep (-3180, 288): a grass stripe across the earth/stone block.
- woods_root_caves: the stone column and block under the room's top earth row.

Screenshots: `playtests/screenshots/2026-10-10-world07-legacy-tiles/terraces_and_leaf_path_buried_stone_lip.png`
and `woods_deep_and_caves_buried_stone_lip.png` (HEAD left, WORLD-07 right).

Static count of `#` directly over `S`: orchard_terraces 34, woods_root_caves 27, woods_deep 18,
orchard_leaf_path 14, orchard_well 13, orchard_cliff_chimney 8, village_bakery 2,
village_lane_west 1, the_catch 1. Total 118. Wood (`%`) under earth or stone would do the same:
no room has that today.

## Root cause

`GroundAutotile.corner_mask` (ground_autotile.gd, the underlay loop) lets a LATER look count for an
EARLIER one (`at > look`), never the reverse. In a display tile with corners (earth, earth,
stone, stone), earth gets 15, but stone gets SW|SE = 12, the exposed top. The stone layer
draws after the earth layer, so its lip lands over the earth fill. The plan's tests cover
only stone over earth: `(stone, stone, earth, earth) -> earth 15, stone NW|NE`. The reverse
case was never specified.

## Fix

Resolved 2026-10-10; see Resolution. Options considered:
- In `corner_mask`, count an earlier look's corner as solid for a later look when it sits
  directly ABOVE (N edge-neighbour) one of that look's corners. Then the stone under earth
  draws fill under the earth's bottom edge, with no lip. Earth beside stone (the side seams)
  can keep today's outlined face.
- Or count every other look's corner that shares a tile edge, in both directions. That is
  simpler, but it removes the outlined stone faces against earth that the decision chose.

Add the `(earth, earth, stone, stone) -> stone 15` case (or whichever rule is chosen) to
`ground_autotile_test` and to `WangSheet.preview`'s pattern.

## Prevention

The preview pattern needs an earth cap on stone, as orchard_terraces authors it. Any underlay
rule must be checked in all four directions, not only the one the concept painting shows.

## Resolution (2026-10-10)

`GroundAutotile.corner_mask` stops counting a look's own corner when the corner directly above it in the tile
is an earlier solid look. The earlier look's underlay fills that tile instead. Stone standing on earth
keeps its rounded feet.

Re-shot on the fixed tree with the HEAD-diff method
(`playtests/screenshots/2026-10-10-world07-legacy-tiles/fixed_buried_stone_three_way.png`,
`fixed_caves_column_and_tuft_three_way.png`; HEAD | first WORLD-07 | fixed):

- No lip line and no rounded corners inside the ground at:
  - the orchard_terraces pillars;
  - under the orchard_leaf_path slab;
  - the woods_deep block;
  - the woods_root_caves column.
- The earth/stone boundary is one straight line.
- Collision: logged positions are identical to HEAD.
- The stone-on-earth spots (summer_trial c29, spring_trial c49, the_catch) are unchanged from the
  first WORLD-07 run, apart from particles.

**What remains: the boundary sits half a cell low.** Earth now draws over the top 16 px of
the stone cells. On the terraces pillar (col 36) stone starts at world y -1296, not at its
cell top -1312. The root-caves column's top is a flat cut 16 px below its cell. Inside solid
ground this reads cleanly. On an exposed side face, earth art covers 16 px of a cell that
`ground_at()` calls STONE: the only place where the drawn material and the gameplay material
disagree (02 §7.1, roots). Filed as `bugs/earth-over-stone-draws-the-boundary-half-a-cell-low`.
