---
id: bugs/a-flashback-return-glides-the-frame-from-the-past
type: bug
title: After a flashback's travel back the frame opens far from Ivo and slides to him, because the leaving's camera return and the talk's zoom release were still easing behind the black
status: resolved
severity: medium
tags: [camera, cutscene, flashback, travel, fade, talk, story-05]
related: [systems/cutscenes, architecture/story-05-playable-flashbacks, playtests/2026-11-12-story05-flashback-3, bugs/a-teleport-across-the-world-glides-like-a-seam-walk]
created: 2026-11-12
updated: 2026-11-12
source_files:
  - scenes/world/cutscene/cutscene_director.gd
  - scenes/world/camera.gd
  - scenes/world/game.gd
---

## Summary

A flashback's leaving scene ends on a 0 s black and the travel back follows at once. The frame uncovered in the present
was 840 px from Ivo (clamped to the room's far side) at zoom about 2, and slid to him over about 3 s.

## Symptom

Flashback 3's first playtest: `b00_return` showed the pool, Ivo off screen; the log at the return had
`cam_centre=(2390,-480)` with Ivo at x 1550. Flashback 1 hid it: its return point is near the same clamp.

## Root cause

Two eases outlived the cover:
- `CutsceneDirector._end` on a recorded (not skipped) end eases the rig from where the scene left it back to Ivo over
  `RETURN_SECONDS`, the camera following the rig. The travel moved Ivo to the present mid-ease, so the rig lerped from
  the past to the present and the frame clamped to the room's edge on the way.
- The push talk framed at zoom 2 (`Dialogue.zoom`); its end under the black called `release_talk()`, a `pair_duration`
  zoom and pair tween. `GameCamera.snap()` (called by `Game._land_in`) cleared smoothing and glides but left both
  tweens running.

## Fix

- `CutsceneDirector._end` cuts the frame back (zoom to rest, follow Ivo, snap) when the fade is opaque, as a skip does:
  the ease is unseen anyway.
- `GameCamera.snap()` lands a running zoom or pair tween (`custom_step`).
- Tests: `cutscene_director_test.test_an_end_under_an_opaque_fade_cuts_the_frame_back`,
  `camera_test.test_snap_lands_a_released_talk`.

## Prevention

A "snap" or a cut must settle every ease that moves the frame, not only the one it was written for.
