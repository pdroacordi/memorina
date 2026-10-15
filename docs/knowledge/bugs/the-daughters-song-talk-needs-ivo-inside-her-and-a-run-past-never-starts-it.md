---
id: bugs/the-daughters-song-talk-needs-ivo-inside-her-and-a-run-past-never-starts-it
type: bug
title: The daughter's song talk is reached only with Ivo standing inside her sprite, and a narrow auto talk is never started by running past it
status: fixed
severity: low
tags: [dialogue, talkable, auto-start, door, opening, village, story-14]
related: [systems/dialogue, systems/story, bugs/the-boys-talk-prompt-shows-over-the-bell-tower-door-and-up-enters-the-tower, bugs/look-at-the-painting-turns-ivo-the-way-he-already-faces, playtests/2026-10-15-story14-opening-fixes]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - scenes/world/rooms/home_village/contents/village_house.room
  - scenes/world/rooms/home_village/contents/village_elder.room
  - scenes/world/interactables/talkable/talkable.gd
---

## Summary

FIXED 2026-10-15. Was: OPEN, low (STORY-14 review, 2026-10-15). After STORY-14 the auto talk by the house door (`daughter_near`) reaches only west of the girl, so Ivo is in reach only while he overlaps her sprite. The talk no longer starts when Ivo comes home through the door. The spot beside her, east of her, is inside the door's zone, so Up there leaves the house. Separately, an auto talk whose zone is under about 72 px wide never starts when Ivo runs through it at full speed. That covers the daughter's (48 px) and the elder's (48 px; it was already 64 px before STORY-14).

## Symptom

- `d_daughter_by_the_door.png` (playtest 2026-10-15-story14) shows the song talk running with Ivo drawn over the girl, at x 100.
- Ivo arrives home at the door (x 144, facing east). The girl holding the guitar out stands at x 104. Nothing starts, and no prompt shows.
- He stops beside her, east of her (centre about 120-135). Still no prompt, and Up takes the door.
- A headless run of `ivo.tscn` at full speed (192 px/s) through Talkables gave these results. Widths 48 and 64 never start the auto talk; 72, 80, 88 and 96 do.

## Root cause

- `village_house.room:31` is `3,8 = {..., "speaker_offset": -8.0, "reach_east": 0.0}`, which gives a zone from x 56 to 104.
- The girl is at x 104, and the door's zone (col 4) starts at x 128. A zone trimmed to keep more than 22 px from the door ends at her centre line. Ivo's 11 px capsule radius then puts his centre at x 115 or less while he is in reach, on top of her.
- Before STORY-14 the zone was 64 to 160 and covered the door. Ivo was in reach on arrival, and `auto_delay` (0.4 s, "past an arrival's fade") started the song.
- An auto start is due only after `auto_delay` in reach (`Talkable.auto_ready`), and leaving disarms it. Running through a zone gives (width + 22 px) / 192 px/s of time in reach, less the frame or two before `body_entered`. That is under 0.4 s up to a width of about 64 px.
- The elder's zone (`village_elder.room:28`, `reach_west` 0, x 272 to 320) is 48 px. `village_elder.room` says "his talks start as Ivo walks past him", but at a run they do not.

## Fix

Fixed 2026-10-15.
- **The girl holding the guitar out** stands at x 72, by her bed, away from the door. Both house talks there (col 2 the bed, col 3 her song, `speaker_offset` -40) are centred on her and reach 48 px west and 32 px east: x 24 to 104, which is 80 px wide and 24 px short of the door. Ivo is in reach beside her, not inside her. Coming home through the door, a few steps west start the song.
- **The elder's talk** reaches 80 px east of him (x 272 to 352) and none west.
- **Tests:**
  - `talkable_rooms_test.test_every_auto_talk_is_wide_enough_to_start_at_a_run`: every `auto_start` `t` in every room file is at least 80 px wide.
  - `player_talk_test.test_running_through_an_auto_talk_starts_it`: Ivo runs at full speed through an 80 px auto talk and it starts.
  - The run-through script measured: 64 px never fires; 72 px and wider fire.
- **Playtests:** `opening_errand` brings Ivo home at the door and walks him west; `opening_elder` runs him through the elder's zone.

## Prevention

- A `room_files_test` or `village_voices_test` case could check that every `auto_start` `t` is at least 80 px wide (`reach_west + reach_east`).
- A trimmed side should leave at least one body width (22 px) of reach beyond the speaker's sprite edge, so that Ivo can stand beside the speaker, not inside it.
- Playtest an auto talk by running through it, not only by stopping in it.
