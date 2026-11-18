---
id: bugs/the-rig-hand-back-shows-the-seeded-look-ahead-one-frame-before-the-frame-follows-ivo
type: bug
title: At a cutscene rig's hand-back, follow(ivo) writes the 96 px lead into the offset one physics step before the frame moves onto Ivo, so the frame flicks 96 px out and back for one frame
status: fixed
severity: medium
tags: [camera, look-ahead, cutscene, rig, release, hand-back, flicker, mentor, lighthouse, story-39]
related: [bugs/the-mentor-silence-release-eases-to-a-look-ahead-frame-then-cuts-96-px-to-ivo, playtests/2026-11-18-story39-camera-release, bugs/paired-frame-kept-its-look-ahead, systems/cutscenes]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - scenes/world/camera.gd
  - scenes/world/cutscene/cutscene_director.gd
---

## Summary

With the STORY-39 fix (`camera.gd` at 08:31:07, uncommitted), the mentor's talk release now eases onto Ivo plus his lead
(x 11560) and stays there. On the hand-back step the centre goes to x 11464 for one physics step (16.7 ms) and then back to
11560: a 96 px move out and back (192 window px). The permanent cut is gone. This one-frame flick remains, and it fails the
"no step above ~6 px" check. Fixed the same day by the follow() change described under Fix.

## Symptom

`talk_reader_driver.gd` with `CAMLOG=1`, `story37_mentor_talk_setup.json`, pt_BR, reading pace 1.0 s. Ivo stands at x 11656
facing west throughout:

| t | frame | centre x | zoom |
|---|---|---|---|
| 41.412 | 6761 | 11560.03 | 1.000 (rig ease landed) |
| 41.429 | 6764 | **11463.99** | 1.000 |
| 41.445 | 6767 | 11560.00 | 1.000 (rest from then on) |

- Seen in 2 of 2 runs at normal frame rate.
- A spike-capture driver screenshot shows it really rendered:
  - frame 6921: Ivo at window x 816..855;
  - frame 6922: 1008..1047;
  - frame 6923: 816..855 again.
  - Shots: `playtests/screenshots/2026-11-18-story39-camera-release/fixed_*.png`.
- A run that saved a PNG on every frame (~25 fps) never showed it. Several physics steps ran between two renders, so the bad
  state was overwritten before anything drew.

`mentor_wakes` (STORY-38) has the same out-and-back, smaller, and it is identical on HEAD: 11608.36 → 11601.95 → 11608.00
at t 7.88, 6.4 px.

## Root cause

Traced from the code and the log; not confirmed in a debugger:
1. `CutsceneDirector._tick_return` runs in the director's `_physics_process`, after `GameCamera._physics_process` has placed
   the frame for that step.
2. On its last tick it moves the rig to `rig_point_for(centre_for(ivo))`. `centre_for` includes the -96 lead. The
   rig's offset x is 0, because a marker keeps its offset and the STORY-39 change no longer tweens it.
3. Then it calls `camera.follow(ivo)`, which seeds `_look_ahead = -96`. The setter writes `offset.x` at once, but
   `global_position` is still the rig's 11560.
4. Until the camera's next `_physics_process` puts `global_position` back on Ivo (11656), the shown centre is
   11560 - 96 = 11464. On a 60 Hz physics, 1:1-render machine that is one drawn frame.

Before STORY-39 the still-running look-ahead tween wrote 0 back over the seed. The HEAD log shows no 11464 frame, so that
write apparently landed before the draw. The frame cut onto Ivo's x instead
(`bugs/the-mentor-silence-release-eases-to-a-look-ahead-frame-then-cuts-96-px-to-ivo`).

`camera_test.gd` `test_a_talk_released_under_a_rig_hands_back_without_a_step` misses this, presumably because it samples the
centre only after a full camera step, never between `follow()` and the camera's next `_physics_process`.

## Fix

Fixed in STORY-39 (`scenes/world/camera.gd`, 08:48:50). After seeding the look-ahead, `follow()` shifts `global_position.x`
by the change in `offset.x`, so the frame drawn before the camera's next step stays where it was.

Verified in play (`playtests/2026-11-18-story39-camera-release`), largest per-frame step from control return to +2 s, no
spike over 40 px:
- mentor release: 2.68 px in each of 2 runs, resting on 11560;
- `mentor_wakes`: 4.52 px, landing 11608.36 → 11608.09 → 11608.00 (the 6.4 px dip is gone too).

## Prevention

Log the camera centre on every rendered frame (`_process`/`frame_pre_draw`), not only after physics steps, and never at a
frame rate low enough to batch physics steps.
