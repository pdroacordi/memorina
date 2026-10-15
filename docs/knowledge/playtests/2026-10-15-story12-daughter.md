---
id: playtests/2026-10-15-story12-daughter
type: playtest
title: STORY-12 - the daughter standing and holding the guitar out as idle loops, facing Ivo, feet on the floor
status: active
build: 28f72da (STORY-12 uncommitted)
area_tested: "village_house: opening_errand, village_return, village_at_06"
tags: [story-12, daughter, staging, ambient-motion, opening]
related: [systems/story, systems/props, playtests/2026-10-15-story03-opening]
created: 2026-10-15
updated: 2026-10-15
ratings: { fun: 3, fluidity: 4, aesthetics: 4 }
screenshots:
  - screenshots/2026-10-15-story12-daughter/daughter_strip.png
  - screenshots/2026-10-15-story12-daughter/a_holding_out_0.png
  - screenshots/2026-10-15-story12-daughter/a_08_five_played.png
  - screenshots/2026-10-15-story12-daughter/f_standing_0.png
  - screenshots/2026-10-15-story12-daughter/e_03_guitar_back_on_the_wall.png
---

# STORY-12: the daughter in motion

The user: "The child in the second shown frame is too static (and too different from the one in the first shwon frame)" (2026-10-15).

Runs:
- `opening_errand`, with a new burst `g_holding_out_0..4`, 1/6 s apart, before the morning talk;
- `village_return`;
- `village_at_06`, with a new burst `g_standing_0..4` from the start.

All three exited 0. The project was reimported first.

## The frames (`daughter_strip.png`)

- **Row 1, HoldingOut** (`opening_errand`): she holds the guitar out east to Ivo by her bed. The guitar bobs and her head moves between frames, and her feet stay on the floor.
- **Row 2, Standing at 0.6** (`village_at_06`): she breathes and shifts by the drawings, faces east, and is greyer with the house's memory. Ivo drops in from the teleport.
- **Row 3, Standing during the guitar beat** (`opening_errand`, the stand-in): she faces east toward Ivo as he plays (`08_five_played`, `m_hold_*`). The last cell (`12_turned_to_the_wall`) is the bed stage, so she is back in bed.
- **Row 4, Standing after the return** (`village_return`, `03_guitar_back_on_the_wall`); `00_at_the_guitar` shows her at the guitar, out of this crop.
- Standing and HoldingOut are now one girl: both were redrawn on the guitar pose's pixel grid (contracts `story_daughter_standing`, `story_daughter_guitar_out`). I did not compare them to the seated pose frame by frame.

The STORY-03 screenshots that show her standing or holding out were retaken from these runs: a_06, a_08, a_09, a_10, e_03, f_00 and f_01.

## What screenshots cannot show

- Her loop runs on the memory clock: it moves at the village's level and would stop below 0.2. She moves in every run here, including at 0.6.
- At 6 fps her breathing is slow and small, and it reads as alive without pulling the eye from the talk.
