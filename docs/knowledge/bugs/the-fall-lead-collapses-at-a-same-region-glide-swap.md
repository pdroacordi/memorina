---
id: bugs/the-fall-lead-collapses-at-a-same-region-glide-swap
type: bug
title: Multiplying the fall lead by (1 - _glide_weight) zeroes it on the swap frame of every same-region fall, so the frame stops for a frame and then trails Ivo, and the landing shows later (0.14 s ahead instead of 0.22 s)
status: resolved
severity: low
tags: [camera, fall-lead, glide, feel, world-05]
related: [playtests/2026-10-10-camera-on-falls, bugs/the-fall-lead-jumps-the-frame-when-a-glide-swaps-into-a-narrow-room, bugs/the-frame-stalls-at-the-floor-seam-before-the-fall-lead-takes-over]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/camera.gd
---

## Resolution (2026-10-11, revision 5, camera.gd 00:14:34, re-measured in game)

The `1 - _glide_weight` factor is gone. Instead the lead moves the frame down at most `fall_lead_follow` (1200 px/s, 20 px per frame), measured from the last step's frame centre. 60 fps `log`, two runs each:
- **counterweights → mill:** no stop on the swap (t 2.57). The frame moves +18..+19 every frame from the seam to the mill's clamp, and Ivo stays 214-223 px above the frame's bottom. The landing shows 0.20-0.21 s (12-13 frames) ahead (rev 4 0.14 s, rev 3 0.22 s).
- **woods_deep → caves:** no stop on the swap (t 2.09). The frame moves +10..+13 per frame, matching Ivo, and the landing shows 0.21 s ahead (rev 4 0.18 s).

## Summary

Revision 4 (camera.gd 23:40:24) multiplies the lead by `1 - _glide_weight` so it no longer overrides a glide's start (the lake_well fix). In a same-region drop the frame has already yielded into the room below before the swap, so the glide has almost no distance to cover. Its weight still starts at 1, which removes the lead exactly when Ivo is fastest. On the swap frame the frame stops. It then grows back over the 0.45 s glide while Ivo falls at up to 1000 px/s.

## Symptom

60 fps `log`, two runs each with the same numbers.

- **orchard_counterweights → orchard_mill_town** (`camfall_a1d_counterweights_dense`). Ivo falls 16.7 px per frame.

  | t | cam_centre y step | feet → frame bottom |
  |---|---|---|
  | 2.55 | +18 | 214 |
  | **2.56 (swap)** | **0** | 197 |
  | 2.58 → 2.63 | +10, +8, +8, +11 | 191 → 168 |
  | 2.65 | +25 | 176 |
  | 2.66 → | +8, +6, +5 | 167 → 145 |

  The landing shows 0.14 s (8 frames) before touchdown. Revision 3 showed it 0.22 s (13 frames) ahead with no stop at the swap.
- **woods_deep → woods_root_caves** (`camfall_a2d_deep_to_caves_dense`): one frame at 0 on the swap (t 2.09), then +15, and the frame falls behind (+10, +9, +8, +7 against Ivo's +10..+12). The landing shows 0.18 s ahead (rev 3: 0.21 s).
- In the canopy walk-off the swap comes after the landing is already in view (`camfall_e1d_canopy_ledge_walk_off_dense`), so it is unaffected: 0.29 s ahead.

## Root cause

`_glide_weight` measures how far the glide still has to go, not how far the frame is from where the glide wants it. A glide that starts with the frame already in place still weighs 1 at its start.

## Fix

Not fixed. Options:
- Scale the lead by how far the glide still has to move (`_glide_from.length() * _glide_weight` against a few px), not by the weight alone.
- Or include the current lead when `set_bounds(glide)` measures `_glide_from`, so that a frame already yielded starts a near-zero glide and the lead never has to be removed.

## Prevention

camera_test: a subject falls at 1000 px/s across a same-region seam with the frame already yielded into the room below. Assert that on the swap frame and the next 10 frames the frame moves down at least half the subject's step.
