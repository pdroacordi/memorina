---
id: playtests/2026-10-15-story11-memorina
type: playtest
title: STORY-11 - Ivo raises, plays and lowers the Memorina in a performance; the mentor raises and plays his flute during his phrase
status: active
build: 3f91b30 (STORY-11 uncommitted)
area_tested: "trials_winter (a Freeze performance at x 160) and lighthouse_interior (mentor_gift)"
tags: [story-11, memorina, animation, mentor, performance, beat]
related: [systems/animation, systems/story, systems/songs-and-the-memorina, playtests/2026-10-15-story10-guitar]
created: 2026-10-15
updated: 2026-10-15
ratings: { fun: 4, fluidity: 4, aesthetics: 4 }
screenshots:
  - screenshots/2026-10-15-story11-memorina/ivo_draw_play_lower_strip.png
  - screenshots/2026-10-15-story11-memorina/mentor_raise_play_strip.png
  - screenshots/2026-10-15-story11-memorina/perform_b_draw_2.png
  - screenshots/2026-10-15-story11-memorina/perform_c_play_0.png
  - screenshots/2026-10-15-story11-memorina/perform_d_perf_08.png
  - screenshots/2026-10-15-story11-memorina/perform_d_perf_34.png
  - screenshots/2026-10-15-story11-memorina/gift_m_raise_2.png
  - screenshots/2026-10-15-story11-memorina/gift_m_play_0.png
  - screenshots/2026-10-15-story11-memorina/gift_m_after_phrase.png
  - screenshots/2026-10-15-story11-memorina/gift_07_flat_note.png
---

# STORY-11: the Memorina in motion

The user: "Should have an animation for when playing memorina too." (2026-10-15). Before this change, `memorina_draw` and `memorina_idle` were frames of the idle sheet, so Ivo played every song with empty hands.

The project was reimported before the runs (`gotchas/a-replaced-sheet-plays-the-old-import-until-reimported`). Both runs exited 0.

## Runs

- **`story11_memorina_perform`** (new; real clock, winter trial floor, Freeze known): Ivo draws, plays the six notes and the Freeze performance runs. Screenshots:
  - `b_draw_0..5`: 1/24 s apart through the draw;
  - `c_play_0..7`: 1/8 s apart through the notes;
  - `d_perf_00..39`: every 0.25 s, each with a log.
- **`mentor_gift`** (rerun): `m_raise_0..4` 0.1 s apart from the phrase's start, `m_play_0..7` 0.25 s apart, and `m_after_phrase`.

## Ivo (`ivo_draw_play_lower_strip.png`)

- **The draw** (row 1) lifts the flute from his belt to his lips in 0.33 s. The camera's push-in during the draw makes him grow across the strip; that is the camera, not the sprite.
- **Playing** (rows 2 and 3): the flute stays at his lips while his head and shoulders sway. The logs show `memorina_idle` looping through the notes and the whole performance (`paused=true` from 6.90 s to 13.65 s). The AnimationTree is ALWAYS only for the performance, as the pause-mode map says.
- **Lowering** (row 4): after the thaw the sheathe plays `memorina_lower` (13.90 s) and Ivo is idle by 14.15 s. The colour the pulse brought back is visible around him.
- **In a talk**: the MEMORINA pose (the `memorina_flat` beat) raises the flute and plays it (`gift_07_flat_note`). He lowers it when the talk ends (`gift_09_stasis_fading`).

## The mentor (`mentor_raise_play_strip.png`)

- Holding, the still, sits exactly where the strip starts (frame 0 matched to the still by mask: offset (-61, -126), flipped east). The swap shows no jump.
- He raises the flute to his mask (`raise`, 0.5 s) as the winter pulse opens, then plays it (`play`, looped). He keeps playing in grey after the pulse fades, until the phrase's 2.6 s end. Then the beat releases its stand-in and Holding returns with `memorina_in_hand` (`m_after_phrase`).
- The gift, the cross-fade to EmptyHand and the stasis are unchanged (`gift_09_stasis_fading`, `gift_10_stasis`).

## What screenshots cannot show

- At 8 fps the playing loop is calm and reads as breathing into the flute. The draw and lower at 12 fps are quick enough not to delay the first note.
- No input waits on the draw: the component is DRAWN at the press and the clip only changes the look. This is from the code; the runs did not press a note during the draw.
