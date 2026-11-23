---
id: bugs/a-talk-resumed-after-a-cutscene-places-its-box-under-the-scenes-camera
type: bug
title: A talk resumed after a cutscene beat places its dialogue box under the scene's camera, so "Essa é…" opens the bottom box over Ivo and his new flute
status: resolved
severity: medium
tags: [story-35, dialogue, dialogue-box, placement, cutscene, camera, resume, mentor, lighthouse, face-height]
related: [playtests/2026-11-23-story35-hand-over, architecture/story35-memorina-hand-over, bugs/the-mentors-lantern-talk-opens-the-top-box-over-his-face, systems/dialogue, systems/cutscenes]
created: 2026-11-23
updated: 2026-11-23
source_files:
  - scenes/world/dialogue/dialogue_director.gd
  - scenes/ui/dialogue_box/dialogue_box_side.gd
  - scenes/world/cutscene/world_cutscene_context.gd
  - scenes/world/camera.gd
  - scenes/world/game.tscn
---

## Summary

`DialogueDirector.resume()` calls `_begin()`, which emits `box_placed(_side())` from the canvas transform of that frame.
After `memorina_hand_over` that frame still has the scene's camera: zoom 2.88 easing back (when played) or zoom 1.5 at the
scene's centre (when skipped). With that camera the keeper's face lies above `TOP_BOX_BOTTOM`, so the box opens at the
BOTTOM. At the talk's own framing it would open at the TOP, as it does for every other line of the talk. The bottom box
covers Ivo from head to feet through "Essa é… essa é a música dela." and the choice. Those are the two beats the plan
keeps him holding the flute for.

## Symptom

STORY-35 playtest (pt_BR, build 9ca29d9d + the uncommitted STORY-35 tree), `story35_hand_over.json` and
`talk_reader_driver.gd` runs:

- "Muitas mãos. Nenhuma guardou." opens at the TOP. "Essa é…" (n=8) and the choice open at the BOTTOM. "Sua também…" is
  back at the TOP. The box changes side twice in four lines.
- Played: the scene ends at ~28.90 and the line opens the same frame, with `[cam]` at (11656, -1284), zoom 2.88. The ease
  back to (11628, -1360), zoom 1.5 finishes at ~29.65, with the box already at the bottom
  (`playtests/screenshots/2026-11-23-story35-hand-over/06_her_song_box_over_ivo.png`).
- Skipped: one rendered frame at zoom 1.5 centred on the scene's point (11628, -1308), then (11628, -1360) the next frame.
  The box is placed on the first of the two (`08_skip_one_frame_at_scene_centre.png`, `09_skip_box_over_ivo.png`).

## Root cause

The side is chosen from the camera of the frame `resume()` runs on, not from the framing the talk returns to.
`lighthouse_top.room` 23,20 has `face_height` 110, so the face is at y -1358:

| Camera | Face screen y (game px) | Side |
|---|---|---|
| Talk framing (11628, -1360), zoom 1.5 | 183 (> 176) | TOP (`opposite`) |
| Played resume (-1284), zoom 2.88 | -33 | BOTTOM |
| Skip resume (-1308), zoom 1.5 | 105 | BOTTOM |

The talk framing clears the top box by only 7 px, so any transient camera above it flips the side.

## Fix

Fixed 2026-11-23, at the root: the box's side is read from the frame the talk settles on, never from the frame shown.
- `GameCamera.settled_canvas_transform(subject)` is the canvas transform the frame rests on while following `subject`: the rest zoom (a framed talk's), the talk's pair and lift or the look-ahead fully eased, the room's clamp and its yield to the body. It mirrors `_framed_position`, `_apply_bounds` and `_keep_subject_in_view` (`camera_test.test_the_settled_frame_is_the_talks_framing_whatever_is_shown`: it equals the shown canvas once a lifted talk has settled, and is unchanged while a rig holds a scene's frame elsewhere at zoom 2.88).
- `DialogueDirector.camera` (wired to `World/Camera2D` in `game.tscn`) makes `_side()` read that transform at every `_begin()`: a talk's start and every resume. Every scene that hands a talk back (the lantern's, the flashbacks', any `CutsceneBeat`) resumes through `resume()` and `_side()`, so none can place the box from its own camera. With no camera (the unit suites) the shown canvas is read, as before (`dialogue_director_test.test_a_resumed_talk_places_its_box_from_its_own_frame`).
- The skip's stray frame: `GameCamera.snap()` now places the frame on its subject at once. Before, a cut that followed this step's camera update drew one frame where the rig stood, at the new zoom (`camera_test.test_a_snap_places_the_frame_at_once`).

## Prevention

A cutscene test that resumes a framed talk could assert that the side after the scene equals the side the talk opened
with, given the same speaker positions.
