---
id: bugs/the-ring-tie-wedge-draws-a-hard-diagonal-between-two-backdrops
type: bug
title: The room ring splits the void between two rooms on an undithered 45-degree line, so where their backdrops differ (a region seam, a narrow room under a wide one) a hard diagonal shows in the sky or beside a wall
status: resolved
severity: medium
tags: [backdrop, shader, room-ring, seam, region-seam, open-top, aesthetics]
related: [playtests/2026-10-11-room-ring-regression, bugs/the-ring-dividing-line-leaves-a-one-pixel-diagonal-hole-above-a-seam, architecture/backdrop-seams, systems/backdrops, systems/rooms]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/environment/backdrop/backdrop_layer.gdshader
  - scenes/world/environment/backdrop/backdrop_math.gd
  - scenes/world/rooms/room_ring.gd
---

## Summary

In the void, `keeps` gives a pixel to the room with the smaller `rect_distance` (the farther-axis distance). Ties go to
the lower x, then y. Past a seam, and at every L-shaped corner of two rooms, that boundary is a 45-degree line, and it
is hard (not dithered). Where the two rooms draw different backdrops, the line is a stark diagonal seam.

## Symptom

Played on the uncommitted room-ring change (on 9f55197), 2026-10-11, in `playtests/2026-10-11-room-ring-regression`.

- **lane_west / woods_edge** (region seam, wall top over the seam at x -1280, y 0; `open_sky_region_cut_lane_to_woods.json`,
  still `rg_2_90`). The frame rises 62 px into the ring with lane_west current. Above the seam, woods_edge's grey-teal
  sky covers the wedge x < -1280 + |y|, a straight 45-degree line through the village's blue sky.
- **village_mill under lake_waterfall_path** (region seam at y 0; `ring_mill_step_to_ledge.json`, still `mill_2_00`).
  The frame is raised over the mill. Left of x 2560 above y 0, the waterfall path's dark forest meets the mill's light sky
  on a diagonal.
- **lake_well under lake_fishing_village** (same region; `camfall_d1_fishing_well_jump.json`, still `s02.45`). During the
  glide into the well, the frame shows up to 62 x 181 px right of the well's wall (x > 1920) and below the village floor
  (y > -1536). On main that strip was void. Now it is the well's cave backdrop below a 45-degree line from the corner
  (1920, -1536) and the village's light fill above it, with a dither triangle on the line.

Screenshots: `playtests/screenshots/2026-10-11-room-ring-regression/03_ring_wedge_hard_diagonal_at_region_seams.png`,
`03b_ring_wedge_whole_frames.png`, `04_lake_well_glide_ring_corner.png`. On a seam between rooms of one backdrop set
(woods_pond / bloom_hollow) the wedge is invisible except for the 1 px hole of
`bugs/the-ring-dividing-line-leaves-a-one-pixel-diagonal-hole-above-a-seam`.

## Root cause

- `backdrop_layer.gdshader:110-120` and `BackdropMath.keeps`: `theirs < mine || (theirs == mine && before(...))` with
  `rect_distance` the Chebyshev distance. Above two side-by-side rooms whose tops are at one height, both distances
  equal `|dy|` for every pixel in the wedge `|dx| < |dy|` past the seam, so the tie-break hands the whole wedge to the
  lower-x room. Around an L-shaped corner (one room's side, the other's floor), the boundary is the diagonal `dx = dy`.
- The ring section of `systems/backdrops` makes the dividing lines hard on purpose ("The void's dividing lines are hard,
  not dithered"). The seam band dithers only pixels whose jittered point lies inside a room, so a ring line gets no blend.
- The user asked for the opposite at seams (2026-10-10, quoted in `systems/backdrops`, "Seams blend"): "The transition in
  kind of the same room when a part of the room is grey and the other isn't is not that good, its just a line, could have
  more of a gradient or something like that."

## Fix

Not fixed. Options:
- Break ties along the seam's own axis, so the vertical seam continues straight up into the void instead of turning
  diagonal. This is the design question raised in `bugs/the-ring-dividing-line-leaves-a-one-pixel-diagonal-hole-above-a-seam`.
  It removes the wedge over side-by-side tops, not the diagonal at L-shaped corners.
- Dither the ring's dividing lines like the seam band: apply `seam_jitter` to the point before the nearest-room test, with
  the same float margin that fixes the 1 px hole.
- For a narrow room beside or under a wider one (lake_well, caldera_cistern), decide whether the void beside the narrow
  room should draw that room's backdrop at all. Today it reads as open cave behind an outer wall.

## Prevention

Unit tests sample ownership only (one owner per pixel), so they pass. A windowed still of the frame in the ring over a
region seam, and over each narrow-under-wide corner, belongs in the room-ring playtest set. Compare the colour step
across the ring's dividing line with the step across a dithered seam band.

## Resolution (2026-10-11)

`BackdropMath.void_owner` and the shader's `owns_void` are changed together. A void pixel goes to the nearest room, measured three ways:
- by the gap in y, for a room whose columns hold the jittered x;
- by the gap in x, for a room whose rows hold the jittered y;
- by `rect_distance`, for any other room (corners).

On a tie, a room whose columns or rows hold the pixel beats a corner, then the lower x wins, then the lower y. Over two side-by-side open tops, a pixel over a room's columns is therefore that room's: the seam runs on straight up. Because the column test uses the jittered x, the 64 px seam band dithers on past the tops, as it does inside the rooms. Diagonal dividing lines remain only at true corners: the inner corner of an L, or diagonal to every room.

Tests:
- `backdrop_math_test.test_the_seam_runs_straight_over_two_open_tops`: ownership over each room's columns. Both owners appear among the jitter cells just past the seam. Every sampled pixel has one owner.
- The `room_ring_test` sweeps (every pixel exactly one resident owner, world and trials) pass with the new rule.

Played (`open_sky_seam_wall_top_full_jump.json`, on 9f55197 plus this change): the full jump, with the frame at the ring's top, keeps the left edge at the body's need and no drift. I did not re-measure the line pixel by pixel; the stills are in the scratchpad.
