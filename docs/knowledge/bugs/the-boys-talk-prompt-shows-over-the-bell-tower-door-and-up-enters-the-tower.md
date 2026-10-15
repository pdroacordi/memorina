---
id: bugs/the-boys-talk-prompt-shows-over-the-bell-tower-door-and-up-enters-the-tower
type: bug
title: Beside the bell tower door the boy's talk prompt and the door's prompt show together, and Up enters the tower
status: fixed
severity: low
tags: [dialogue, talkable, door, prompt, up, village, story-09]
related: [systems/dialogue, systems/story, systems/rooms, systems/props, bugs/ivo-faces-the-talkable-not-the-villager-beside-it]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - scenes/world/rooms/home_village/contents/village_square.room
  - scenes/world/interactables/talkable/talkable.gd
  - scenes/world/interactables/door/door.gd
  - scenes/characters/components/talk_component.gd
  - scenes/characters/components/door_component.gd
---

## Summary

FIXED 2026-10-15. Was: OPEN, low (STORY-09 review, 2026-10-15). The boy's Talkable (`village_square.room` `19,8`, one cell wide) touches the bell tower door's zone (col 20). Over a 17 px band both `look_up` prompts are visible, and Up there takes the door. A player who stops east of the boy and presses Up to talk enters the bell tower.

## Symptom

Square-local x of Ivo's origin, floor y 288:

| x | Talk prompt | Door prompt | Up does |
|---|---|---|---|
| 597 to 602 | shown | hidden | nothing |
| 602 to 629 | shown | hidden | talks to the boy |
| 629 to 634 | shown | shown | talks to the boy |
| 634 to 651 | shown | shown | **enters the bell tower** |

The playtest timelines (`village_voices.json`, `village_voices_06.json`) place Ivo at x 624, outside the band, so the run did not show it.

## Root cause

- Prompts and reach read different shapes. `Talkable._physics_process` and `Door._refresh` (`door.gd:146`) show the prompt while Ivo's body (capsule radius 11, 22 px wide) overlaps the zone. `TalkComponent.reachable()` and `DoorComponent.reachable()` read the 12 px wide `DoorSensor`.
- `Player._process_motion` tries `_try_door` before `_try_talk`, so a door in sensor reach wins, as `systems/dialogue` specifies.
- Talk zone x 608 to 640, door zone x 640 to 672. The body bands overlap from 629 to 651; the door's sensor band starts at 634. Nothing hides the talk prompt while a door wins the press. The one-cell width (`systems/story`: "so the bell tower door at col 20 keeps Up") keeps Up for the door but not the prompt honest.

## Fix

Fixed 2026-10-15 in content. The boy's talk moved to col 17, one cell wide (x 544 to 576), `speaker_offset` 40 (the boy at x 600), west of him. It is 32 px from the house of notes' door at col 15 and 64 px from the bell tower's at col 20, more than Ivo's 22 px body, so only one prompt shows at a time. Between the talk and the tower door (x 603 to 629) no prompt shows and Up does nothing.

The bakery had the same 16 px gap: its errand talk (col 6, two cells) stood beside the door at col 4. It is now one cell wide, 32 px from the door.

`village_voices_test.test_no_village_voice_stands_within_a_body_of_a_door` holds every talk in the four voice rooms to more than 22 px from every door zone on its row. `test_the_boys_talk_faces_him` pins the offset. Both timelines end with Ivo at x 616 (no prompt; Up leaves him in the square, `g_band_616_after_up`) and at x 580 (the talk prompt, `g_talk_580`).

The code option (a prompt only where the press would take it) is not done; the content rule and the test cover the village.

## Prevention

Every Talkable that stands within a body width (22 px) of a door or an item pickup is ambiguous. A `room_files_test` case could flag a `t` zone within 22 px of an `E` zone in the same row. Playtest a talk beside a door from both sides, not only from the clean spot.
