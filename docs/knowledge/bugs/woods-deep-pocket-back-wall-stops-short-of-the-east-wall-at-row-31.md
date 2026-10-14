---
id: bugs/woods-deep-pocket-back-wall-stops-short-of-the-east-wall-at-row-31
type: bug
title: woods_deep's pocket [back] wall stops at col 43 on row 31, so its east edge and an outer corner show beside the ground instead of under it
status: resolved
tags: [rooms, back-wall, dual-grid, autotile, world-31, woods-deep, review]
related: [systems/backdrops, systems/rooms, architecture/backdrop-seams]
created: 2026-10-13
updated: 2026-10-13
source_files:
  - scenes/world/rooms/spring_woods/contents/woods_deep.room
  - scenes/world/rooms/maps/room_tile_resolver.gd
---

## Summary

RESOLVED 2026-10-13 before commit, low (WORLD-31 review, not yet seen in a still). In `woods_deep.room` the `[back]` row 31 (file line 117) covers
cols 23-43, but row 32 covers cols 23-44. Cell (44,31) is ground on the pocket's east side, and it is not beside the open
shaft (cols 42-43, rows 28-30). The systems entry's rule says the back wall goes "one cell into the ground around it, but
not beside the open shaft", so this cell should be `#` in `[back]`.

## Details

- `RoomTileResolver.resolve` autotiles `map.back` on its own (`_layers(map, map.back, false)`) with the same corner
  masks and look sheets as the ground. A back cell with no back neighbour therefore gets an edge tile: a dark edge, and
  a rounded outer corner where two sides are open.
- At the vertex between (43,30), (44,30), (43,31) and (44,31), only (43,31) is back. That is a lone-corner tile, so the
  wall's corner is rounded at the top-right of (43,31). The woods backdrop shows through the notch at the east end of
  the shaft's straight sky line.
- At the vertices down the col 43/44 boundary on row 31, the back's edge is drawn inside (43,31). The ground at
  (44,31) draws only its own half, so the back wall's dark edge runs beside the ground's edge instead of under it.
  This is the doubled edge that the "one cell into the ground" rule for cave-mouth columns exists to prevent
  (`systems/backdrops`, Seams).
- Row 32 already reaches col 44, and the west end of the shaft line (vertex (41..42, 30..31)) is a straight back edge.
  Only this one cell is out of line with the rule.

## Fix

Make `[back]` row 31 run to col 44: line 117 becomes 23 dots, 22 `#`, then 15 dots, matching line 118. Then re-import
(`--import`), run `backdrop_seams_test` (it should not change, because (44,31) is ground), and take a still of the
shaft's foot.

## Prevention

When a `[back]` fill encloses a hollow, check every open cell's four ground neighbours against the stated rule, not
just the rows that look symmetric. A test could check this: every `[back]` cell's orthogonal ground neighbour carries
`[back]` too, unless it borders open air that has no back.

## Fix

Applied 2026-10-13, before the WORLD-31 commit: row 31 of `[back]` now matches row 32 (cols 23-44). The generating rule had excluded every ground cell with an open non-pocket cell among its eight neighbours, and (44,31) touches the shaft's cell (43,30) only at a corner; a corner contact does not put the back wall beside open sky, because the ground at (44,30) covers it.
