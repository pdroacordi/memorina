---
id: playtests/2026-10-15-story10-guitar
type: playtest
title: STORY-10 - Ivo's guitar as a six-frame loop, held and strummed, in the morning song (Try again and Lower)
status: active
build: 394b341 (STORY-10 uncommitted)
area_tested: "village_house: the guitar beat of opening_errand and opening_lower"
tags: [story-10, guitar, animation, beat, opening]
related: [systems/animation, systems/story, playtests/2026-10-15-story03-opening, gotchas/a-replaced-sheet-plays-the-old-import-until-reimported]
created: 2026-10-15
updated: 2026-10-15
ratings: { fun: 3, fluidity: 4, aesthetics: 4 }
screenshots:
  - screenshots/2026-10-15-story10-guitar/hold_and_strum_strip.png
  - screenshots/2026-10-15-story10-guitar/b_strum_strip.png
  - screenshots/2026-10-15-story10-guitar/a_08_five_played.png
  - screenshots/2026-10-15-story10-guitar/a_11_silence_hold.png
---

# STORY-10: the guitar in motion

The user: "the sprite for playing the guitar is very wrong. Not the style of Ivo character. Better redo it. Also,
transform it into animation, not static. Simple animation" (2026-10-15).

Timelines `opening_errand` and `opening_lower`, rerun with bursts of screenshots during the guitar beat:
- `m_hold_0..5`: 1/6 s apart, in the 2 s silence at the gap after "[Try again]";
- `m_strum_0..5`: 1/24 s apart, from the first note of the second attempt (`opening_errand`) and of the Lower attempt (`opening_lower`).

Both runs exited 0. Their stills replace the `a_` and `b_` screenshots of `playtests/2026-10-15-story03-opening`.

## What the frames show

- **The hold moves** (`hold_and_strum_strip.png`, top row): six different poses in one second. The strumming hand rises and falls, the head nods and the guitar rocks, and the feet stay on the floor line. He is never still while the guitar pose holds.
- **The strum** (bottom row; `b_strum_strip.png`) runs the same six frames in half a second. A note 0.4 s after the last one restarts it from frame 0 before it ends, so a steady run of notes reads as continuous strumming. Once the notes stop, the hold picks up from frame 0, the frame after the strum's last, with no pop.
- The style is Ivo's own: his idle palette, head and proportions, and the house guitar's colours (`ivo_sheet_test` `HELD_PROPS`).
- After the talk he returns to idle without the guitar (`a_12`, `b_07` in the STORY-03 folder). The lowered guitar stands by the stove (`b_04`).

## What screenshots cannot show

- At 12 fps the strum is quick enough to match a press. At 6 fps the hold is calm, but on sheet frame 3 the guitar body moves 2 art px (4 game px) back and returns, so it reads as rocking more than resting. That comes from the art, not the timing. If it reads as jitter in motion, slowing the hold to 4-5 fps is a one-line change to the clip.
- The first run showed Ivo vanishing in four of six frames: the game was still playing the old 2-frame import (`gotchas/a-replaced-sheet-plays-the-old-import-until-reimported`). After `--import` every frame draws.
