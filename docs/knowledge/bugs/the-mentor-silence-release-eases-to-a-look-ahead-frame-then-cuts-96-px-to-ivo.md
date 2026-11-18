---
id: bugs/the-mentor-silence-release-eases-to-a-look-ahead-frame-then-cuts-96-px-to-ivo
type: bug
title: After the mentor's talk the frame eases ~0.8 s toward Ivo's 96 px look-ahead point, then cuts 96 px back onto him in one frame
status: fixed
severity: medium
tags: [camera, look-ahead, cutscene, dialogue, release, mentor, lighthouse, story-34, story-39]
related: [bugs/the-rig-hand-back-shows-the-seeded-look-ahead-one-frame-before-the-frame-follows-ivo, playtests/2026-11-18-story39-camera-release, playtests/2026-11-17-story34-mentor-at-the-lantern, bugs/paired-frame-kept-its-look-ahead, systems/cutscenes, systems/dialogue]
created: 2026-11-17
updated: 2026-11-18
source_files:
  - scenes/world/camera.gd
  - resources/cutscene/story/mentor_silence.tres
---

## Summary

When the mentor's talk ends (the `mentor_silence` zoom-2 hold, then control), the camera eases from (11600, -1308) at zoom 2
toward (11560, -1332) at zoom 1. That point is Ivo's feet x 11656 plus a -96 px look-ahead (he faces west). On the frame the
zoom lands, the centre cuts to x 11656, a 96 px jump at zoom 1 (192 window px).

## Symptom

STORY-34 playtest, third run (zoom 1.5 with `frame_lift` 64). A per-frame `[cam]` log of `get_screen_center_position()` and
zoom (`talk_reader_driver.gd`, `CAMLOG=1`):

| t | Centre | Zoom |
|---|---|---|
| 40.92 | (11599.9, -1308.0) | 1.899 (ease starts as control returns, t 40.90) |
| 41.42 | (11567.1, -1312.3) | 1.109 |
| 41.687 | (11559.99, -1331.92) | 1.000 |
| 41.704 | **(11656.00, -1332.00)** | 1.000 (the next logged frame) |

Ivo stands still at x 11656 throughout. Reproduced in all three runs of the session: the first and second runs' 0.5 s
`log` samples show the same 11572/11581 → 11656 pair. So it is not caused by the zoom 1.5 / `frame_lift` change.

## Root cause

The talk is released while the cutscene's rig is the followed subject: `release_talk` -> `release_pair` ->
`_tween_look_ahead()` started a 0.4 s tween of `_look_ahead` toward `_look_ahead_target()`, which is 0 for a marker.
`CutsceneDirector._tick_return` eases the rig to `rig_point_for(centre_for(ivo))`, a centre that includes the 96 px lead
over the held offset, then calls `follow(ivo)`. `follow` seeded `_look_ahead = 96 * facing` but killed a running
look-ahead tween only when the new subject was a marker. The tween begun under the rig was still running and wrote 0 over
the seeded lead on the next physics step: a 96 px cut onto Ivo's x, and no lead afterwards until his next turn.

## Fix

Fixed in STORY-39 (`scenes/world/camera.gd`):
- `follow()` kills a running look-ahead tween for every subject, so the lead it seeds for a Character stands.
- `_tween_look_ahead()` only kills while the subject is not a Character: a followed marker keeps the offset it was given,
  and `follow()` seeds the lead when a Character is followed again.

Test: `camera_test.gd` `test_a_talk_released_under_a_rig_hands_back_without_a_step` (no per-frame step of 6 px or more
over the 60 frames after the hand-back, and the frame ends on Ivo plus his lead).

## Prevention

For every talk or cutscene release, log the camera centre per frame and check for a step. Stills taken 0.5 s apart missed
this for two runs.
