---
id: bugs/a-dropped-cutscene-replays-the-gesture-it-gives-back
type: bug
title: A dropped cutscene gives a staging back its earlier StagedStrip stand-in by showing it again, so the strip replays its intro instead of resting on its held last frame
status: resolved
severity: low
tags: [cutscene, drop, stand-in, fact-staging, staged-strip, line-gesture, story-35, mentor, hand-over]
related: [systems/cutscenes, systems/story, architecture/story35-memorina-hand-over, gotchas/animatedsprite2d-stop-rewinds-and-never-emits-finished]
created: 2026-11-23
updated: 2026-11-23
source_files:
  - scenes/world/cutscene/world_cutscene_context.gd
  - scenes/world/environment/props/fact_staging.gd
  - scenes/world/story/staged_strip.gd
---

## Symptom

Open, found in the STORY-35 review by reading the code, not reproduced in a run. If `memorina_hand_over` is dropped after `Giving` shows, the keeper does not go back to the held-out flute. He cuts to `hold_out` frame 0 (the Holding composite) and plays the 0.4 s hold-out gesture again. `memorina_hand_over_test.test_a_drop_shows_the_held_out_flute_again` checks only the shown child's name, so it passes. The same happens to any `StagedStrip` stand-in that a drop gives back, for example a `LineGesture` with `holds = true`.

## Root cause

`WorldCutsceneContext._restage` (world_cutscene_context.gd:322-333) gives the earlier stand-in back with `staging.stand_in(before[2])`. That call makes the strip visible again. `StagedStrip._on_visibility_changed` (staged_strip.gd:14-18) plays `intro` from frame 0 every time the strip is shown. When the scene's own stand-in hid the strip, it was stopped, and stopping rewinds it to frame 0 (`gotchas/animatedsprite2d-stop-rewinds-and-never-emits-finished`). So "the rest shown before shows again" (systems/cutscenes, Drop) brings back the strip's first frame, not the frame that was on screen.

Reachability: low. The hand-over plays only from the mentor's talk. While a talk runs, Ivo is held STILL in a room with no creature and no exit he can take, so no hurt, hazard or room change can drop the scene (systems/cutscenes, "The hand-over", Rest). The code path is general, though: it covers every drop of every scene that uses `CutsceneStage`.

## Fix

Fixed 2026-11-23 (first option). `WorldCutsceneContext.stage` records a `ShownBefore` (inner class) per staging before the scene's first `CutsceneStage`: its pick, its stand-in and, for a `StagedStrip`, its clip, `frame` and `is_playing()`. On a drop, `_restage` stands the child in again, then `StagedStrip.resume_at(clip, frame, playing)` puts the strip back on that frame and pauses it there if it was held, or plays on from it if it was mid-intro. `FactStaging` stays the only writer of visibility; the context writes only the strip's frame. `memorina_hand_over_test.test_a_drop_shows_the_held_out_flute_again` checks that `HoldingOut` is on its last frame, not playing, and still there 10 frames later.

## Prevention

A drop test should check the strip's `frame` and `is_playing()` as well as `FactStaging.shown()`. Anything that shows a `StagedStrip` again has to choose between replaying it and resting on its held frame.
