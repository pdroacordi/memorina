---
id: bugs/the-first-guardian-talks-zoom-hides-the-guardian-behind-the-dialogue-box
type: bug
title: The first Frost guardian talk hid the golem behind the top dialogue box (Bloom fixed by zoom 1, Frost by a box placed off its face)
status: resolved
severity: low
tags: [guardians, dialogue, talk, zoom, camera, story-18]
related: [systems/guardians, systems/dialogue, playtests/2026-10-30-grd08-story18-guardian-clips-and-talks]
created: 2026-10-30
updated: 2026-10-30
source_files:
  - resources/dialogue/guardians/guardian_bloom.tres
  - resources/dialogue/guardians/guardian_frost.tres
  - scenes/ui/dialogue_box/dialogue_box.gd
  - scenes/ui/dialogue_box/dialogue_box_side.gd
  - scenes/world/dialogue/dialogue_director.gd
  - scenes/world/interactables/talkable/talkable.gd
---

## Summary

`guardian_<id>_first` has `zoom = 2.0`. At 2x the camera frames Ivo and the guardian with their feet
in the lower half, and the box opens at the top (panel art y 20..88 = game y 40..176). A 120 px stag
becomes 240 screen px tall and a 176 px golem 352, so the box covers the speaker's head for the
whole first talk (6 lines and the gesture). Frost shows only from the hips down, and its crown is cut
by the top of the frame above the box. Ivo's face is half under the box's bottom edge in some lines.
The repeatable `_again` talk has no zoom and frames both fully.

## Reproduction

`tools/playtest/scripts/guardian_fight_talk_driver.gd`, `guardian_bot_bloom.json` / `guardian_bot_frost.json`
(max_duration 260), `BOT_GOD=1`. After RESTORED and the lesson the driver walks into the Talkable's reach
and presses Up. It happens with Ivo at the reach edge (Bloom B run: stopped as the prompt showed) and
standing on the guardian (Bloom A).

Screenshots: `playtests/screenshots/2026-10-30-grd08-story18-guardian-clips-and-talks/bloom_talks.png`
(frames 240-247, the stag's head behind the panel; 250 is the unzoomed repeat), `frost_talks.png` (425-431),
`bloom_prompt_and_zoomed_talk.png` (left).

## Cause

The zoom and the box's top placement were sized for villagers (about 48 px tall). The box side is
chosen from the mean screen y of the speaker point and Ivo's feet (`DialogueBoxSide.opposite`). Both
are feet, so a tall speaker always gets the top box, which is where its head is.

## Fix direction (not decided)

A lower `zoom` for the guardians' first talks (1.25-1.5 would keep the Frost golem under y 176), or a
box side chosen from the speaker's head height. The Frost crown leaving the frame at 2x points to
the zoom.

## Partial fix (2026-10-30): Bloom fixed, Frost open

`guardian_<id>_first` now has `zoom = 1` (data only): the camera still pairs the guardian with Ivo, at the fight's
scale. Bloom: the whole stag stands under the top box for all six lines and the gesture (`fix_round_bloom.png`,
bottom row).

Frost cannot be framed whole under the top box at any zoom of 1 or more in `lake_frost_arena`, so its upper half still
sits behind the box (`fix_round_frost.png`, bottom). The numbers: the top box covers screen y 40..176 of 360. The room
is 384 px tall with its floor at y 288, so the camera's room clamp puts the feet at screen y 264..288 at zoom 1. The
golem is 184 px tall, so its top is at screen y 80..104, and 72-96 px of it are behind the box. Fitting it needs
`feet_y - 184 * zoom >= 176` with `feet_y <= 288 * zoom` (the clamp at the room's top), which has no solution for
zoom >= 1. The bottom box covers the feet (y 212..348). The bug's suggested 1.25-1.5 did not take the room clamp
into account.

Options (a design call, not taken): a shorter top box or a box at the side for tall speakers; for a speaker over
about 100 px, place the box by the speaker's head height; let a talk's frame go past the room clamp; or accept the
portrait standing in for the golem's face.

## Fix (2026-10-30, STORY-19): Frost

"Caixa pela cabeça" (user, 2026-10-30): the box is placed by the speaker's head height. `Talkable.face_height` (px from
the feet to the eyes; Frost 150, 0 for every other speaker) reaches `DialogueDirector.start_dialogue`, and
`DialogueBoxSide.place` opens the bottom box when those eyes are above `DialogueBox.TOP_BOX_BOTTOM` (176 screen px).
Playtest (`guardian_bot_frost.json` to 259 s, `BOT_GOD=1`, HOLD): every line of the first talk and the repeat open the
bottom box (`boxpos (0, 0)`); the golem shows from its crown to its ankles, only its feet under the box, and Ivo shows
from the head up over the box's top edge (`playtests/screenshots/2026-10-30-grd08-story18-guardian-clips-and-talks/story19_frost_bottom_box.png`).
Bloom keeps the top box (its eyes clear it at zoom 1). Tests: `dialogue_box_side_test`, `dialogue_director_test`
(`test_a_tall_speakers_face_keeps_the_box_off_it`), `dialogue_box_test` (`TOP_BOX_BOTTOM` matches the panel).
