---
id: bugs/the-frame-jumps-up-when-the-fall-reach-closes-under-a-yielded-frame
type: bug
title: When the fall reach closes while the frame stands yielded into it (a shake, or the frame's x leaving the covering rooms), the frame returns to the room clamp in one step, up to ~170 px
status: open
severity: low
tags: [camera, fall-lead, reach, shake, feel, core-07]
related: [bugs/the-fall-lead-shows-the-void-beside-a-narrower-room-below, bugs/the-fall-lead-jumps-the-frame-when-a-glide-swaps-into-a-narrow-room, playtests/2026-10-10-camera-on-falls, systems/rooms]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/camera.gd
  - scenes/world/game.gd
  - scenes/world/rooms/fall_reach.gd
---

## Summary

`fall_lead_follow` limits only downward motion. If `Game._fall_reach_for` returns the bare room bounds on a step after it returned a larger fall reach, `GameCamera._keep_subject_in_view` clamps `centre.y` back to the room's clamp at once. Found in review of the CORE-07 working tree (2026-10-11). Worked out from the code, not reproduced in game.

## Symptom

- Step N: the fall reach is open, and the frame stands D px below the room's floor seam. In the woods_canopy walk-off the playtest logs the frame at y -780 against the canopy's clamp at -948, so D = 168.
- Step N+1: `FallReach.of` finds the strip uncovered and returns the bounds. `_yield_axis(centre.y, shown, …, _fall_reach.end.y - half.y)` returns the room's clamp, so the frame rises D px in one step.
- Step N+2: if the strip is covered again, the frame comes back down at 20 px per step (`fall_lead_follow`).
- Before the close, the frame shows a few px of void for one step, because Game tests last step's frame.

Triggers in the current world:
- **A shake while falling, with the frame flush against the edge of the rooms below.** `Game._fall_reach_for` builds the strip from `_camera.view_rect()`, which includes the shake displacement. The shake is applied after `_last_centre_y` but before Game reads the rect, and it can be up to ±4 px on `hurt` and ±2 px on `hit_landed`. Example: woods_canopy over woods_deep, with the frame clamped at the west or east wall. The two rooms have the same width and nothing lies beside woods_deep at r-2, so a 1 px outward shake uncovers the strip.
- **The frame's x leaving the covering span.** In orchard_chasm_bridge (2 columns) over orchard_terraces, only c-7 is covered, so the reach is open only while the frame is clamped at the west wall. During the fall, a look-ahead turn to the east or air drift to the east unclamps x and closes the reach. The timing is marginal before the swap.

## Root cause

- The fall reach is recomputed from scratch every step, with no hysteresis.
- The lead's yield is a clamp against that rect, not a motion. A shrinking rect therefore moves the frame by the whole difference, and nothing limits the upward move.
- Coverage is tested against the shaken, one-step-stale frame rect.

## Fix

Not fixed. Options:
- Limit the frame's return too. While `_fall_lead > 0`, do not let the lead branch place `centre.y` above `_last_centre_y - fall_lead_follow * delta`. This can show a few px of void for a few steps.
- Expose the frame rect without the shake (computed before `_update_shake`) and build the strip from it in `Game._fall_reach_for`.
- Keep a fall reach that was granted open while the frame is still below the room's floor seam, and clamp the frame's x into the covering span instead of closing it.

## Prevention

camera_test: with the fall reach open and the frame yielded 100+ px below room A's bottom, call `set_reach(ROOM_A, ROOM_A)` (the reach closes) and step once. Assert that the frame's bottom rose by no more than one `fall_lead_follow` step. Add a Game-level or `FallReach` test where a 1 px shift of the strip uncovers it.

## Resolution (2026-10-11, revision 7)

The shake half is fixed: `Game._fall_reach_for` measures the strip from `GameCamera.steady_view_rect()`, the frame without this step's shake, so a hurt or hit shake no longer closes the reach (test: `camera_test.test_the_steady_frame_leaves_the_shake_out`). The sideways-drift half remains: where the room below spans only part of the room above (orchard_chasm_bridge over orchard_terraces), a look-ahead turn or air drift that moves the frame past the covered span closes the reach and the frame returns to the room clamp in one step. Left open, low: easing the frame up would show void beside the narrower room for those frames.
