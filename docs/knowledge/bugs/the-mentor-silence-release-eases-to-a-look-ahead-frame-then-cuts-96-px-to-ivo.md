---
id: bugs/the-mentor-silence-release-eases-to-a-look-ahead-frame-then-cuts-96-px-to-ivo
type: bug
title: After the mentor's talk the frame eases ~0.8 s toward Ivo's 96 px look-ahead point, then cuts 96 px back onto him in one frame
status: active
severity: medium
tags: [camera, look-ahead, cutscene, dialogue, release, mentor, lighthouse, story-34]
related: [playtests/2026-11-17-story34-mentor-at-the-lantern, bugs/paired-frame-kept-its-look-ahead, systems/cutscenes, systems/dialogue]
created: 2026-11-17
updated: 2026-11-17
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

Suspected, not traced:
- `GameCamera.centre_for` adds `look_ahead_distance * facing` while not pairing (`camera.gd` ~291-302).
- The release eases toward that lead.
- When the hand-back completes (the zoom tween lands), something sets `_look_ahead` to 0, or the follow target drops the
  lead, in one step instead of through `_tween_look_ahead`.

`bugs/paired-frame-kept-its-look-ahead` is the closest prior case (look-ahead and paired frames).

## Fix

Not fixed. Either release onto the subject's actual follow centre, including whatever lead the follow keeps after the
hand-back, or tween the look-ahead from its current value when the follow resumes. Check that the per-frame centre has no
step above ~6 px across the release.

## Prevention

For every talk or cutscene release, log the camera centre per frame and check for a step. Stills taken 0.5 s apart missed
this for two runs.
