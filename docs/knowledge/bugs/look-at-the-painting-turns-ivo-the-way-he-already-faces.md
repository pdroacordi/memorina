---
id: bugs/look-at-the-painting-turns-ivo-the-way-he-already-faces
type: bug
title: "[Look at the painting]" shows nothing - the beat turns Ivo to the painting, which is on the same side as the elder he already faces
status: fixed
severity: low
tags: [story, beat, dialogue, elder, choice, opening]
related: [systems/story, architecture/the-opening-is-staged-by-save-facts, playtests/2026-10-15-story03-opening]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - scenes/world/rooms/home_village/contents/village_elder_contents.tscn
  - scenes/world/rooms/home_village/contents/village_elder.room
  - scenes/characters/ivo/player.gd
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
