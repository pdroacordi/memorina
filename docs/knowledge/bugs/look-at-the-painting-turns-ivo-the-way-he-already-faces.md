---
id: bugs/look-at-the-painting-turns-ivo-the-way-he-already-faces
type: bug
title: "[Look at the painting]" shows nothing - the beat turns Ivo to the painting, which is on the same side as the elder he already faces
status: fixed
severity: low
tags: [story, beat, dialogue, elder, choice, opening]
related: [systems/story, systems/cutscenes, architecture/the-opening-is-staged-by-save-facts, playtests/2026-10-15-story03-opening, playtests/2026-10-16-story16-opening]
created: 2026-10-15
updated: 2026-10-16
source_files:
  - scenes/world/rooms/home_village/contents/village_elder_contents.tscn
  - scenes/world/rooms/home_village/contents/village_elder.room
  - scenes/characters/ivo/player.gd
  - scenes/world/dialogue/dialogue_director.gd
  - resources/cutscene/story/ivo_walks_to_painting.tres
---

## Summary

FIXED 2026-10-15, low (STORY-03 phase B review, 2026-10-15). The LET gesture of `elder_story` cues `elder_painting`, a STILL beat whose only action is `face` = `LighthousePainting6`. The painting is at x 410 and the elder at x 272. The elder's auto zone is x 128 to 224 (col 5, 3 cells). Ivo is always left of both and already faces right, so the gesture shows a 1.5 s pause and no movement.

## Symptom

`playtests/2026-10-15-story03-opening` reports "Ivo turns to the painting (`c_05`)". But `c_03_a_good_end.png` and `c_05_turned_to_the_painting.png` show Ivo in the same pose, facing right. The script's "Ivo walks to it", amended in the plan to "turning to the painting", is not visible. The choice reads as nothing happening.

## Root cause

`Player.pause_talk` only calls `face_towards(signf(at.x - global_position.x))`. With the speaker and the painting on the same side of every point in the Talkable's zone (`village_elder.room` `5,8`, `village_elder_contents.tscn:111`), the sign never changes.

## Fix

Fixed 2026-10-15. The elder's Talkable moved to col 10 (x 336, two cells, `speaker_offset` -64), between the elder (x 272) and the painting (x 410): Ivo walks past the elder, faces him (west) through the story, and "[Look at the painting]" turns him east. A beat's `face` now holds until the talk's end (`DialogueDirector._facing`), so the elder says "East. Past the fields…" behind him, as the script has it ("Ivo walks to it. The elder, behind him"). Tests: `dialogue_director_test.test_a_beat_face_holds_until_the_talk_ends`; playtest c (`c_03`, `c_05`, `c_06`).

## Prevention

A `face` beat is a visible action only if the face point is on the other side from the speaker. Check every Talkable zone x against both points when placing it.

## Revision (2026-10-16): regressed by STORY-16

Reopened, low (STORY-16 review). STORY-16 replaced the `StagedBeat` `Beats/ElderPainting` (`face = ../../Props/LighthousePainting6`) with a `CutsceneBeat` that plays `ivo_walks_to_painting`: Ivo walks to `Marks/Painting` (x 392) and faces east. The new node (`village_elder_contents.tscn:164`) sets no `face`. `DialogueDirector._play` therefore keeps `_facing` on the elder (`dialogue_director.gd:151`). When the talk resumes, `Player.begin_talk` turns Ivo back west to him (`player.gd:1203`) before "Is that lighthouse still there?". The elder's "East. Past the fields…" is no longer said behind him. `playtests/2026-10-16-story16-opening` `e02` shows Ivo facing the elder on that line.

The same resume also undoes the last beat of two other talks: `IvoHearsStory` (`village_house_contents.tscn:434`, Ivo turns to the door) and `GateBolt` (`village_elder_contents.tscn:169`, Ivo turns east to the bolt). Ivo turns back to the speaker for the frame the talk ends.

Fix (not applied): give `ElderPainting` its old `face = NodePath("../../Props/LighthousePainting6")` (x 410, east of the mark Ivo stops on). Give the two others a mark on the side they turn to, or the door. `test_a_beat_face_holds_until_the_talk_ends` tests the mechanism, not this data. Add a rooms test: every `CutsceneBeat` whose scene ends with Ivo facing or walking names a `face` on that side.

Fixed again 2026-10-16 (STORY-16), at the mechanism and in the data:
- `DialogueBeat.face_after(facing)` is asked as a beat ends and sets `DialogueDirector._facing`; `CutsceneBeat` answers the side its scene last turned or walked Ivo to (`CutsceneDirector.ivo_turned()`, noted by the context's `face` and on a walk's arrival). A face a scene gives him therefore holds to the talk's end without the data repeating it.
- The data names it too: `ElderPainting` has its `face` (the painting) back, `IvoHearsStory` faces `Marks/Door` (x 152, east of Ivo at 136) and `GateBolt` faces `Marks/Outside` (x 608, east).
- Test: `cutscene_beat_test.test_a_face_the_scene_gives_ivo_holds_to_the_talks_end` (a scene turns him away from the speaker; after the resume he still faces the scene's side). Playtest: `playtests/2026-10-16-story16-opening`, second round.
