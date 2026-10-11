---
id: bugs/the-frame-stalls-at-the-floor-seam-before-the-fall-lead-takes-over
type: bug
title: In a fast same-region drop the frame stops dead at the room's floor seam for two physics frames, then lurches 15-28 px, before the fall lead takes over
status: resolved
severity: low
tags: [camera, rooms, fall-lead, glide, feel, world-05]
related: [playtests/2026-10-10-camera-on-falls, bugs/walking-off-a-ledge-above-a-same-region-seam-drops-the-frame-in-one-step, bugs/the-fall-lead-jumps-the-frame-into-a-room-the-body-already-touches-below, systems/rooms]
created: 2026-10-10
updated: 2026-10-11
source_files:
  - scenes/world/camera.gd
  - scenes/world/game.gd
---

## Resolution (2026-10-11, revision 6, camera.gd 00:20:24, re-measured in game)

- **The seam stall** (frame still at the room clamp while the lead had not yet taken over) has been fixed since revision 4. The counterweights crossing moves +15..+19 px every frame.
- **The slow-drift rest over a one-way:** the ground cap now casts rays at the body's left and right edges and caps only when both hit. After the woods_deep walk-off lean, the frame rests 3 frames (t 1.63-1.65) instead of 8. Those 3 are the frames in which Ivo's whole body is still over the one-way at y 384; he moves ≤2 px per frame, 121-125 px above the frame's bottom. It then follows continuously (+14, +6, +4..+7 per frame). Two runs, same numbers.
- **Holds with the landing already in view** are accepted as intended, as an engineering judgement and not a user decision (coordinator, 2026-10-11): the camera need not move while the landing shows. These are the woods_canopy walk-off (6 frames at y -780, at the ground cap) and 1 frame at y 564 in woods_deep → caves.
- **No regression:** the landing on screen is 0.21 s (woods_deep → caves) and 0.28-0.29 s (canopy walk-off) before touchdown. Landings on floors just above a seam (canopy ledge, square floor) still never put the frame past the room's bottom, and the largest step is +11/+12 px.

## Status after revision 5 (2026-10-11, camera.gd 00:14:34, re-measured in game)

**Engineering judgement, not a user decision (coordinator, 2026-10-11):** a hold while the landing is already in view is accepted as intended, because the camera need not move while the landing shows. Revision 5's holds of that kind:
- woods_canopy walk-off: 6 frames at y -780 (t 1.82-1.91), at the ground cap.
- woods_deep → caves: 2 frames at y 564 (t 2.28-2.29).

**Still open, because revision 5 shows one hold with the landing NOT in view.** This was the rule for closing the bug.
- **Where:** woods_deep → caves (`camfall_a2d_deep_to_caves_dense`; same numbers in revision 4). After the walk-off lean (+8, +13, +13, +6), the frame rests for 8 frames at y 244 (t 1.63-1.72).
- **Ivo meanwhile:** he falls 1.5-3.3 px per frame, and his feet go from 127 to 110 px above the frame's bottom. The landing (y 704) is 280 px below the frame.
- **Cause:** the ground cap's ray hits the one-way at y 384 (x -3584..-3520) under Ivo, which he drifts past without landing on. The lead stays capped at that ledge + 32 px until he leaves its column at x -3520. The frame then resumes at +16, +15, +10.
- **Not a tracking loss:** Ivo is never near the edge. HEAD holds the frame still over the same frames, with the feet down to 3 px from the edge. It is the one case of a still frame with the landing out of view.
- **Possible fix:** cap at the ground the body will reach given its horizontal velocity, or ignore a one-way the body is moving off. Or close this bug as accepted, if a slow-drift hold well inside the frame is judged fine too.

## Status after revision 4 (2026-10-11, camera.gd 23:40:24, re-measured in game)

**The seam stall is fixed.** In orchard_counterweights → orchard_mill_town the frame moves +15..+19 px every frame from t 2.23 to the swap. There is no zero frame and no +5/+26 hiccup (two runs).

**Still open:** on the woods_canopy walk-off (`camfall_e1d_canopy_ledge_walk_off_dense`, two runs), the frame holds still for 5 frames (t 1.83-1.90, y -780) while Ivo falls 8-19 px per frame. Then it resumes at +21 on the swap.
- The landing (-640) is already in view, so tracking is not lost; it reads as a hitch.
- The frame's bottom sits at the ground cap (landing + 32 + 8 px), and `_apply_bounds` still clamps the follow to the canopy's bounds. So nothing moves the frame until the swap.
- Revision 4's earlier fall-reach grant did not change this. Revision 3 held 3-4 frames here.

The one zero frame at every same-region swap is a separate, new cause: `bugs/the-fall-lead-collapses-at-a-same-region-glide-swap`.

## Status after revision 3 (2026-10-10, 23:27:39, re-measured in game)

Still open, smaller. The lead's target is now `max(fall_view * air, follow_bottom - feet - margin)`.
- counterweights → mill: the frame no longer stops dead. One frame remains at +5 px (Ivo +13.9), followed by a +26 px catch-up (Ivo +14.2) at t 2.29-2.30. Every other frame moves +14..+18 px.
- A canopy ledge walk-off still holds the frame still for 3 frames at y -780, at t 1.81-1.88, then +21 px at the swap. The landing is already in view there; the frame waits at the canopy clamp because `_apply_bounds` still clamps the follow to the room.
- The follow term created a new one-frame step at fall onset: `bugs/walking-off-a-ledge-above-a-same-region-seam-drops-the-frame-in-one-step`.

## Summary

While Ivo falls inside a room, the vertical follow centres the frame on him: at full speed his feet are ~185 px above the frame's bottom. The fall lead asks only for feet + 8 + `_fall_lead` (~160 px at 850 px/s). The room clamp therefore stops the frame at the floor seam ~25 px before `_reach_for` admits the room below (lead end past the seam, read one frame late). For two physics frames the frame stands still while Ivo falls 14-15 px per frame. Then the yield catches up in one 28 px step.

## Symptom

Seen in game on the 23:15:20 working tree. The same frames appear on the first (22:56) version of the change. 60 fps `log`, `camfall_a1d_counterweights_dense`: orchard_counterweights → orchard_mill_town, seam y -1536.

| t | feet y | cam_centre y | step | feet → frame bottom |
|---|---|---|---|---|
| 2.28 | -1728.1 | -1721 | +16 | 187 |
| 2.29 | -1714.2 | -1716 (clamp) | +5 | 178 |
| 2.31 | -1700.0 | -1716 | **0** | 164 |
| 2.33 | -1685.6 | -1716 | **0** | 150 |
| 2.34 | -1670.9 | -1688 | **+28** | 163 |
| 2.35 → 2.45 | | | +18..+20 per frame (Ivo +15..+16) | back to 184 |

- woods_deep → woods_root_caves (`camfall_a2d_deep_to_caves_dense`), at lower speed: the frame stands at the clamp, then starts with a +15 px step from rest (t 1.82). After that it moves 8-12 px per frame.
- Screenshots of the counterweights run show two consecutive frames with the background unmoved, then a large shift.
- The old code had a 0.2 s stop at the same place, with Ivo pinned to the bottom edge, so this is much smaller than before. It still reads as a hitch at ~900 px/s. That is inferred from the numbers; a human playtest should confirm it.

## Root cause

- The follow's natural frame and the lead's requirement disagree by ~25 px.
- In `_reach_for`, the fall reach starts only when `body.end.y + 8 + fall_lead()` passes the seam. Game runs before the camera and the player each step, so it reads the previous step's lead and body.
- `_apply_bounds` clamps the follow to `_bounds`, not `_reach`, so the frame waits at the seam until the requirement alone forces a yield.

## Fix

Not fixed. Options:
- Grant the fall reach once the frame's unclamped bottom (follow position + half height) would pass the seam, not only the lead's end.
- Or, while a fall reach is granted, clamp the follow against the reach rather than the room bounds, so the in-room follow simply continues.

## Prevention

camera_test: drop a subject at 850 px/s across a same-region floor seam. Assert that the frame's per-step vertical motion never falls to 0 while the subject is airborne and above its landing.
