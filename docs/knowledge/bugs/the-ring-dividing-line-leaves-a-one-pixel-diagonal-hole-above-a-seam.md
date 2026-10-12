---
id: bugs/the-ring-dividing-line-leaves-a-one-pixel-diagonal-hole-above-a-seam
type: bug
title: Where two room rings meet on a 45-degree line, both rooms' near backdrop layers skip the line's pixels, so a 1 px diagonal of the far layer shows in the sky above a seam
status: resolved
severity: medium
tags: [backdrop, shader, room-ring, seam, float, open-top]
related: [systems/backdrops, systems/rooms, architecture/backdrop-seams, bugs/the-drawn-frame-correction-flips-between-candidates-and-drops-ivo-out-of-frame, gotchas/two-quads-disagree-on-a-pixels-world-position, gotchas/glsl-gdscript-math-must-be-duplicated, playtests/2026-10-11-room-ring-regression, bugs/the-ring-tie-wedge-draws-a-hard-diagonal-between-two-backdrops]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/environment/backdrop/backdrop_layer.gdshader
  - scenes/world/environment/backdrop/backdrop_math.gd
  - tests/scenes/world/rooms/room_ring_test.gd
---

## Summary

The room ring's nearest-room test (`backdrop_layer.gdshader:110-120`, `BackdropMath.keeps`) has no float margin: a
pixel goes to the room whose `rect_distance` is smaller, and a tie goes to the lower x. Above two side-by-side open-top
rooms, the line where one room's distance stops being a tie passes exactly through pixel centres along a 45-degree
diagonal. Each room's layer quads compute `world_pos` slightly differently, so on that line both rooms skip the pixel.

## Symptom

Found in review of the uncommitted room-ring change (on 9f55197) by playing it. Timeline
`tools/playtest/scripts/open_sky_seam_wall_top_full_jump.json`: a full jump from the woods_pond / bloom_hollow seam wall
top (x -5760, top y 0), with the frame risen to the ring (cam_centre (-5491, 20)).

- Every apex still (`j_5_05` to `j_5_65`) shows a 1 game px light diagonal from the seam's top (-5760, 0) up and to
  the right, to about (-5714, -46).
- That is the predicted line x = -5760 + |y|. Up to there the bloom_hollow (lower x) ring wins on the tie; past it,
  woods_pond's ring is nearer.
- The line's pixels are (133, 140, 148), the far layer's colour. Their neighbours are the tree layers, (112, 116, 115)
  and (98, 102, 100). So neither room drew its near layers on the line; one room drew the far layer.
- The line stays put while the camera holds its x, and moves with the frame.
- Above the tree line the far layer is uniform, so the line no longer shows there.

## Root cause

- `keeps` compares `theirs < mine` and `theirs == mine` exactly. Every other ownership test in the file uses
  `SEAM_EPSILON`, so that two shaders that disagree both draw and never both skip. That rule is in
  `architecture/backdrop-seams` ("Float safety").
- The new clause breaks it, and with Chebyshev distance its dividing lines are diagonals through pixel centres:
  - above or below every seam between two rooms whose top (or bottom) is at one height: x = seam ± |dy|, with the tie
    going to the lower x;
  - at every L-shaped room corner.
- `world_pos` (`backdrop_layer.gdshader:42`) is `MODEL_MATRIX * VERTEX`, interpolated per quad. The quads of two
  rooms (and of two layers) do not give bitwise-equal positions for one screen pixel
  (`gotchas/two-quads-disagree-on-a-pixels-world-position`).
- `room_ring_test` and `backdrop_math_test` sample exact pixel centres in doubles, so they cannot see this.

## Fix

Not fixed. Options:
- Bias the ring toward overdraw, as the jitter test does: own keeps when `mine <= theirs + e` (or `<` for the
  tie loser), with `e` larger than the quads' disagreement. Overdraw is harmless only if the layers are opaque, and
  this set has translucent layers. Check the doubled line too.
- Better: decide on a position every quad shares. Snap `world_pos` to its pixel centre before the test
  (`floor(world_pos) + 0.5` at zoom 1), or derive it from `SCREEN_UV` and a camera-rect global uniform. The
  ownership is then bitwise the same in every quad, and `BackdropMath.keeps` already samples pixel centres.
- Separately, a design question: the 45-degree tie wedge above a seam hands the higher-x room's sky to the lower-x room.
  A tie-break by the other axis would continue the seam straight up. That matters where the two backdrops differ (region
  seams such as village_lane_west / woods_edge).

## Prevention

A windowed check, not a unit test: a still with the frame in the ring above a seam between two open-top rooms, scanned
for a 1 px diagonal that differs from both neighbours (the scan used here: a pixel whose colour differs from the pixels
3 px left and right, which match each other). Any shader ownership test shared by several quads needs a margin, or a
position every quad computes the same way.

## Playtest evidence (2026-10-11, room-ring regression)

Reproduced independently in `playtests/2026-10-11-room-ring-regression`. In a fresh run of
`open_sky_seam_wall_top_full_jump.json` (still `j_5_25`, cam (-5462, 20)), the 1 game px light diagonal runs up and to
the right from the seam's top, where this entry predicts it (`playtests/screenshots/2026-10-11-room-ring-regression/05_ring_tie_line_one_px_hole.png`).
The wedge itself, visible where the two backdrops differ, is filed separately:
`bugs/the-ring-tie-wedge-draws-a-hard-diagonal-between-two-backdrops`.

## Resolution (2026-10-11)

The shader judges every pixel by its centre, `floor(world_pos) + 0.5` (`BackdropMath.pixel_centre`, its GDScript twin). Two quads that place a pixel a hair apart floor it to the same centre and give one answer, so the exact gap comparisons are safe (`gotchas/two-quads-disagree-on-a-pixels-world-position`). The seam jitter values are even, so a jittered centre never lands on an integer room edge. Over a seam this line no longer exists at all, because the seam now runs straight up (`bugs/the-ring-tie-wedge-draws-a-hard-diagonal-between-two-backdrops`). Diagonals remain only at true corners, and the same snapping covers them.

Test: `backdrop_math_test.test_two_quads_that_disagree_on_a_pixel_give_it_one_owner`. Two rooms judge pixels on the diagonal where their gaps tie, at the inner corner of a tall room beside a short one, each from a position offset by about 0.0004 px the opposite way. Every pixel has exactly one owner. With `pixel_centre` returning the raw point the test fails (110 failures), so it does catch this.
