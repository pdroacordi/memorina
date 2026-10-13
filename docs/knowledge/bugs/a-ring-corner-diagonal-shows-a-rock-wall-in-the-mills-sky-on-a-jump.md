---
id: bugs/a-ring-corner-diagonal-shows-a-rock-wall-in-the-mills-sky-on-a-jump
type: bug
title: With the dither gone, the ring's L-corner rule draws a hard 45-degree wedge of lake_waterfall_path's ice-cave wall in village_mill's sky whenever a jump raises the frame, and backdrop_seams_test allows it as "out of every resting frame"
status: resolved
tags: [backdrop, room-ring, seam, hard-cut, world-28, allowlist, aesthetics]
related: [bugs/the-ring-tie-wedge-draws-a-hard-diagonal-between-two-backdrops, architecture/backdrop-seams, systems/backdrops, systems/rooms]
created: 2026-10-13
updated: 2026-10-13
source_files:
  - scenes/world/game.gd
  - scenes/world/rooms/room_residency.gd
  - scenes/world/environment/backdrop/backdrop_math.gd
  - scenes/world/environment/backdrop/backdrop_layer.gdshader
  - tests/scenes/world/environment/backdrop/backdrop_seams_test.gd
  - scenes/world/rooms/frozen_lake/contents/lake_waterfall_path_contents.tscn
---

## Summary

RESOLVED 2026-10-13 (WORLD-28 review, played; was medium). village_mill (x 1920..3200, y 0..384, `village_valley`) has an open top
west of lake_waterfall_path (x 2560..3200 above y 0), which is now `ice_caves`. In the void above the mill, left of x 2560,
`void_owner` gives the wedge `2560 - x < -y` to the waterfall path (its rows hold the pixel and its x gap is smaller). A
jump from the mill's upper ledges raises the frame, and that wedge shows as a hard diagonal of dark rock against the
valley sky. This is the mill symptom of `bugs/the-ring-tie-wedge-draws-a-hard-diagonal-between-two-backdrops` again. That
fix kept the L-corner diagonal and relied on the dither, which WORLD-28 removed.

## Symptom

`tools/playtest/scripts/ring_mill_step_to_ledge.json` (start (3000, 94), jump left from the row-3 ledge), windowed on
the WORLD-28 worktree. Still `mill_2_00`: camera centre (2852, 80), frame x 2532..3172, top y -100. The top-left corner
shows a dark ice-cave triangle about 28 px across, from game px (0, 72) to (28, 100), cut on a straight 45-degree line
against the light valley sky. A jump that starts further west on the row-5 slab (cols 26-37) shows a wider wedge.
Ordinary play triggers it. Ivo is in the middle of the mill and crosses no seam.

## Root cause

- `BackdropMath.void_owner` / the shader's `owns_void`: at an L-corner both rooms "span" the pixel (the mill by columns,
  the waterfall path by rows), so the smaller gap wins. The boundary is the diagonal `dx = dy` from the corner (2560, 0),
  in open void where no ground or `[back]` wall can hide it. While the backdrops matched (`pine_woods` on both) or
  the dither ran across it, this did not show. WORLD-28 gave the waterfall path a rock wall and made every line hard.
- `backdrop_seams_test.ALLOWED` keys an allowance by room pair and `ring`, not by geometry. Its `CORNER` reason says
  "only a keep-in-view yield past a room's edge shows a sliver of it". Here the yield is the normal jump yield over
  an open top, not a yield past a side edge. The same key also covers the straight seam continuations in the void for
  six other pairs, which are not diagonals (e.g. `lake_chasm|orchard_chasm_bridge ring: x -3200, y -2464..-2304`).

## Fix

Not fixed. Options for `godot-architect`:
- Columns before rows in `void_owner` (both languages, `gotchas/glsl-gdscript-math-must-be-duplicated`): a void pixel
  above or below a room's columns belongs to the nearest such room, and the rows rule applies only where no room's columns
  hold the pixel. At the mill corner the boundary becomes x 2560 continued up. That is the waterfall path's own west edge,
  where its bottom rows are `S` (cols 0-3), so the cut lies against ground. `room_ring_test` must still find one owner
  per pixel, and every other L-corner in `ALLOWED` must be re-checked.
- Or ask the user whether a rock wedge in the sky during a jump is acceptable, like the gatehouse sky line, and record
  the answer verbatim.

## Prevention

- Key ring allowances by geometry (`BackdropCut.describe()` or a line and range), so a new cut between an already-listed
  pair fails the test. Give corner diagonals and straight continuations separate, true reasons.
- For each allowed `ring` cut beside a room with an open top, take a windowed still at a jump apex near the corner. The
  cell walk cannot tell whether a frame reaches it.

## Resolution (2026-10-13)

- **Holds, not gaps.** `BackdropMath.void_owner` and the shader's `owns_void` (changed together) rank how each room
  within `ring` holds a void pixel, then compare gaps only within a rank: ABOVE (in its columns, over its top) 3, BESIDE
  (in its rows) 2, BELOW (in its columns, under its floor) 1, CORNER 0. A room past `ring` never owns the pixel, so the
  rank cannot hand it to a room that does not draw it. The sky over a room is that room's, and under a floor the deeper
  room beside it goes on down (ground, not the short room's sky). Every boundary is straight: a room edge continued, or a
  ring limit. At the mill the boundary is x 2560 continued up against the waterfall path's solid columns 0-3, and
  `backdrop_seams_test` finds it hidden. Played: `ring_mill_step_to_ledge.json`, still `mill_2_00` (scratchpad/w28),
  shows the valley sky up to the waterfall path's stone with no wedge.
- **Glide residency.** A rank can give a pixel in the left room's ring to that room's neighbour, which no longer touches
  the new room (terraces to chasm bridge: the sky over orchard_well; cistern bottom to cistern: over the temple gate).
  `room_ring_test`'s glide sweep found the holes. `RoomResidency.settle` takes the left room's neighbours as `keep`
  during a glide and `Game` settles again on `GameCamera.glide_finished` (first a timer; `bugs/a-stale-glide-timer-idles-the-left-rooms-neighbours-mid-glide`) (the WORLD-22 note "delay the hide by one
  glide"). The glide sweep counts them as resident.
- **Allowlist.** `BackdropCut.key()` names the segment (pair, `rooms` or `ring`, axis, line and span), so a new cut between
  a listed pair fails. Every entry has a reason class checked against the maps and in stills: RING_LIMIT, BELOW_FLOORS,
  UNDER_FLOOR, PAST_WALLS, RINGS_MEET, TRIALS_APART (256 px apart, rings overlapping by 64 px, never resident together) and WELL.
  No diagonal is left in the world or the trials.
- **Cave mouths.** Each side cave-mouth `[back]` column goes one cell into the ground above and below, so the legacy
  stone's ragged edge lies over the back wall, not over the cut (frost_cliffs col 39 rows 4-9, still
  `crop_cave_mouth_col39_after.png`); the mill's back row includes the overhang's corner cell (col 31), which left one
  sky pixel at the seam.
