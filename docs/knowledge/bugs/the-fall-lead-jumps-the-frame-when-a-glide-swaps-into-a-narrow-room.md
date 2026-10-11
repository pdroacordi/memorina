---
id: bugs/the-fall-lead-jumps-the-frame-when-a-glide-swaps-into-a-narrow-room
type: bug
title: When a fall swaps into a narrower same-region room (fishing village to lake_well), the fall lead applies on the swap frame on top of the glide, so the frame drops 66 px at once and then stands still for 2 frames
status: resolved
severity: low
tags: [camera, fall-lead, glide, rooms, void, world-05]
related: [playtests/2026-10-10-camera-on-falls, bugs/the-fall-lead-jumps-the-frame-into-a-room-the-body-already-touches-below, bugs/the-fall-lead-shows-the-void-beside-a-narrower-room-below]
created: 2026-10-10
updated: 2026-10-11
source_files:
  - scenes/world/camera.gd
---

## Re-check (2026-10-11, revision 5): still fixed

`camfall_d1d_fishing_well_dense`, two runs:
- Swap at t 2.49. The frame steps +20, +20, +20 per frame (Ivo +13), then +27, +24, +22, +21 on the glide after the landing.
- HEAD's largest step there is +27. There is no stop.
- The void strip beside lake_well peaks at 53 x 181 px during the glide (HEAD 60 x 180).

## Resolution (2026-10-11, revision 4, re-measured in game)

The lead is multiplied by `1 - _glide_weight`. 60 fps `log`, `camfall_d1d_fishing_well_dense`, two runs:
- The swap frame steps +29 px, then the glide continues at about +21 per frame. HEAD steps +27 on its glide's first frame. Revision 3 stepped +66 and then held 2 frames.
- The void strip beside lake_well peaks at 53 x 181 px during the glide (HEAD 60 x 180).

The same multiplier now removes the lead at same-region swaps where the frame had already yielded: `bugs/the-fall-lead-collapses-at-a-same-region-glide-swap`.

## Summary

Revision 3 (23:27:39) keeps the lead out of lake_well while Ivo is still in lake_fishing_village, which is correct. On the swap frame, lake_well becomes the current room, so the fall reach is its bounds. `_physics_process` adds `_glide_from * _glide_weight` and then calls `_keep_subject_in_view`. That call now yields the frame down by the lead (capped at the landing ground + 32 px) at once, past the glide's start, rather than letting the glide carry it.

## Symptom

60 fps `log`, `camfall_d1d_fishing_well_dense`, two runs with the same numbers.

| t | feet y | cam_centre (x, y) | step y |
|---|---|---|---|
| 2.48 | -1473.7 | (1685, -1646) | +12 (body + 8 follow, as HEAD) |
| 2.50 (swap) | -1460.8 | (1685, -1580) | **+66** (Ivo +12.9) |
| 2.51 | -1447.7 | (1676, -1580) | 0 |
| 2.53 | -1440.0 (lands) | (1668, -1580) | 0 |
| 2.54 → | | | +21, +24, +22 … glide |

- On the swap frame, the frame's x still overhangs lake_well's east edge (x 1920), because the x glide has only just started. The void strip there jumps from 85 x 70 to 85 x 136 px, then narrows as the x glide catches up.
- HEAD shows a void strip here too, but it grows gradually (+27 px on the swap frame, max 60 x 180 px).
- The landing is in view only from the swap frame: 0.03 s ahead, against 0.02 s on HEAD.

## Root cause

The lead's yield runs after the glide offset and is clamped against the new room's reach, so on a glide frame it overrides the glide's start position.

## Fix

Not fixed. Options:
- Skip the lead yield (or blend it by `1 - _glide_weight`) while a glide is in progress.
- Or include the lead when `set_bounds(glide)` measures `_glide_from`, so the glide starts from the lead-adjusted frame.

## Prevention

camera_test: a subject falling at ~770 px/s crosses into a same-region room narrower than the frame, starting a glide. Assert that the frame's vertical step on the swap frame is within the subject's step plus 4 px.
