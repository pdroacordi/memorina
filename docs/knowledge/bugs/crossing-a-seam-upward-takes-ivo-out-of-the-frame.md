---
id: bugs/crossing-a-seam-upward-takes-ivo-out-of-the-frame
type: bug
title: Jumping up through an in-region seam takes Ivo out of the top of the frame for up to ~0.4 s before the glide catches him
status: resolved
severity: medium
tags: [camera, rooms, seam, glide, world-05, feel]
related: [playtests/2026-10-09-traversal-woods-lake, systems/rooms, bugs/a-jump-across-a-horizontal-seam-loses-its-height-in-the-fade]
created: 2026-10-09
updated: 2026-10-10
source_files:
  - scenes/world/camera.gd
  - scenes/world/game.gd
---

## Summary

- The camera stays clamped to the old room's bounds until Ivo's feet cross the seam.
- Going up, his whole body (54 px) passes the top of the frame first.
- The glide into the new bounds then starts slowly: `TRANS_SINE`, `EASE_IN_OUT`, 0.45 s.
- So Ivo is partly or wholly invisible for a few tenths of a second at every upward in-region seam.

## Symptom

Uncommitted WORLD-05 seam work on ea47690 (imported 23:25:32). Screenshot:
`playtests/screenshots/2026-10-09-traversal-woods-lake/rv_upward_seam_ivo_out_of_frame.png`.

**woods_root_caves → woods_deep** (`tools/playtest/scripts/traverse_woods_lake_i7_rv_caves_no_root_double_jump_skip.json`,
logged every 0.05 s). The caves' camera centre y is clamped at 564, so the view's top is y 384.

```
t=2.30 feet 445.5  cam_centre.y 564   head 391: top 7 px of him cut
t=2.51 feet 385.1  cam 564             whole body above the view
t=2.56 feet 374.7  room=woods_deep, cam 563 (glide starts)
t=2.61 feet 371.1  cam 545             still out of frame (frame s2.60: no Ivo)
t=2.66 feet 368.6  cam 508             view top 328; head 315 still cut
t=2.70 feet 367.1  cam 455             visible again
```

Fully out of frame for ~0.15 s; partly out of frame for ~0.4 s.

**woods_deep → woods_canopy** (`traverse_woods_lake_e_deep_climb_to_canopy.json`, double jump up the hole).
In frame e11.1 Ivo is not on screen. The camera centre is still y -588 at t 11.26 and reaches -737 at
t 11.50.

At a side seam the same clamp costs only about one frame (village_square → village_mill, frame f1.80 of
`traverse_woods_lake_w7a_rv_square_to_mill_glide.json`: a sliver of Ivo at the right edge).

## Impact

- The player loses sight of Ivo at the top of a climb: at the point where they aim the next jump or landing.
- In the fade build this was hidden by the black fade. Now it is visible.

## Fix

Not fixed. Options for the implementer:
- Start the glide when Ivo's capsule top (not his feet) leaves the old bounds, or when the camera's
  look-ahead would cross them.
- Use an ease-out (fast start) for the glide instead of the sine in-out.
- Let the frame follow Ivo past the old room's top edge by up to his height before the switch, as long as
  the neighbour is running (it now always is).

## Prevention

A camera test: walk a subject up across a seam between two touching bounds, and assert that the subject's
rect stays inside the view on every physics frame.

## Resolution (2026-10-10)

The current room is now the one holding Ivo's body centre (`Player.body_rect().get_center()`), and the glide
is a cubic ease-out (0.45 s). Re-checked on the uncommitted tree, imported 23:58:40.

"Visible" is the fraction of Ivo's 22x54 body rect inside the 640x360 view, computed from 0.05-0.1 s `log`
samples:

| Crossing | Timeline | Before | Now |
|---|---|---|---|
| woods_deep → woods_canopy | `traverse_woods_lake_e3_rv2_deep_r04_to_canopy_dense.json` | wholly out of frame at t 11.1 | min 0.55, one 0.05 s sample |
| root caves → woods_deep | `..._i11_rv2_caves_root_climb_one_run.json` | wholly out ~0.15 s, partly ~0.4 s | min 0.86, one sample |
| woods_deep → caves (drop) | `..._d1_rv2_deep_pocket_drop_into_caves.json` | - | min 0.49, one 0.05 s sample |

What remains:
- While Ivo bobs at the top rung in the caves (feet 426), his head is cut by the frame's top. Visible
  0.77-0.88 for as long as up is held.
- The body-centre rule brings its own problem: `bugs/a-hop-below-a-seam-flips-the-room-twice`.

2026-10-10, later: Ivo now leaves a room only when his whole body is out of it, and `GameCamera._keep_subject_in_view`
keeps his body plus 8 px in frame. Visible is 1.00 on every sample for deep → canopy, caves → woods_deep, the
top-rung hold (was 0.77-0.88), the woods_deep → caves drop and standing on the mill slab
(`traverse_woods_lake_e3_rv2_…`, `i11_rv2_…`, `d1_rv2_…`, `s3_rv3_…`).
