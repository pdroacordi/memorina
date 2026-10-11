---
id: bugs/walking-off-a-ledge-above-a-same-region-seam-drops-the-frame-in-one-step
type: bug
title: Walking off a ledge 96 px above a same-region floor seam drops the frame 38 px in one physics frame, because the fall lead's follow term is full on the first airborne frame
status: resolved
severity: low
tags: [camera, fall-lead, feel, world-05]
related: [playtests/2026-10-10-camera-on-falls, bugs/the-frame-stalls-at-the-floor-seam-before-the-fall-lead-takes-over, systems/rooms]
created: 2026-10-10
updated: 2026-10-11
source_files:
  - scenes/world/camera.gd
---

## Resolution (2026-10-11, revision 4, re-measured in game)

The lead now grows at most at `fall_lead_rise` (720 px/s, 12 px per frame). 60 fps `log`, two runs each:
- **woods_deep pocket walk-off:** the frame eases down +8, +13, +13, +6 px over 4 frames (rev 3: +38 in one frame).
- **woods_canopy ledge walk-off:** +10, +13, +13 … (rev 3: +38).
- The largest step anywhere in these falls is +16 px. It happens when the ground cap lets go as Ivo leaves the one-way's column, and it is still bounded by the rise rate.

## Summary

`GameCamera._update_fall_lead` (revision 3, 23:27:39) sets its target to `max(fall_view * air_axis, follow_bottom - feet - subject_margin)` whenever `air_axis() > 0`, and a rising target is taken at once. On the first airborne frame of a walk-off, `air_axis` is about 0.01. But the follow term is the standing follow frame's bottom: about 124 px below the feet. A floor 96 px above the seam has a same-region room below that spans the frame, so the fall reach admits it, and the frame drops by the whole difference in one frame.

## Symptom

60 fps `log`, measured in game. The step happens while Ivo moves 0.3 px.
- woods_deep pocket → caves (`camfall_a2d_deep_to_caves_dense`, two runs): `cam_centre` y 204 → 242 (**+38 px**) at t 1.47-1.48. The frame then holds at 243-244 for ~10 frames while the fall speeds up.
- woods_canopy ledge (y -864) walked off to the right (`camfall_e1d_canopy_ledge_walk_off_dense`): -948 → -910 (**+38 px**) at t 1.29. On HEAD the frame stays at -948 (step 0).
- Picture (two captures that straddle a harness hitch, so the shift looks larger than one frame): `playtests/screenshots/2026-10-10-camera-on-falls/04_rev3_walk_off_one_frame_drop.png`.
- Jumps are not affected: the ground cap limits the lead to ~32 px at take-off. Landings showed no step over 12 px.

## Root cause

The follow term is not scaled by fall speed, and the lead rises with no easing (`if target >= _fall_lead: _fall_lead = target`).

## Fix

Not fixed. Options:
- Scale the follow term by the same air axis, or by `smoothstep(0, small, air)`.
- Or let only the `fall_view * air` part rise instantly, and ease the follow term in over `vertical_smooth_time`.

## Prevention

camera_test: a subject on a floor 96 px above a same-region seam starts falling at 0 px/s. Assert that no step in the frame's first 10 airborne steps exceeds the subject's step plus 4 px.
