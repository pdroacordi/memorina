---
id: playtests/2026-09-21-lesson-scene-and-answer
type: playtest
title: The lesson as a scene, the answer on Ivo's sheet, the recall on its cue, weather frozen and woken
status: active
build: 7e9f62c + the round-5 change
area_tested: Frost Edge (weather at 0.2, the charge's recall), Bloom Hollow (listening gate, answer sheet, lesson scene, restored region)
tags: [guardians, lesson, weather, qte, recall, hud, camera]
related: [playtests/2026-09-21-bloom-fight-acts, architecture/memory-runs-through-pause, features/regional-weather]
created: 2026-09-21
updated: 2026-09-21
ratings: { fun: 4, fluidity: 4, aesthetics: 4 }
screenshots:
  - screenshots/2026-09-21-lesson-scene-and-answer/f00_frost_weather.png
  - screenshots/2026-09-21-lesson-scene-and-answer/f01_recall_aura.png
  - screenshots/2026-09-21-lesson-scene-and-answer/b02_answer_sheet_prompt.png
  - screenshots/2026-09-21-lesson-scene-and-answer/b04_answer_half.png
  - screenshots/2026-09-21-lesson-scene-and-answer/c02_lesson_6s.png
  - screenshots/2026-09-21-lesson-scene-and-answer/c05_after_lesson_late.png
---

## What was tested

The same throwaway, state-driven scene as the previous entry (deleted afterwards),
extended: Frost Edge first (weather at baseline 0.2, eight hits, the charge with the roll
recall), then Bloom Hollow (the burst recall, a draw attempted while the guardian sings,
the answer on Ivo's sheet, a second cycle into the lesson, and the region afterwards).
Real seconds were counted through the pause and the slow (`delta / Engine.time_scale`).

## Findings

- **The Frost Guardian could not move at all** in its arena: the lighthouse contents were a
  copy of the woods, whose low floating platform (tiles 4-6 at row -6) sat exactly on the
  176 px capsule's head, wedging it into the floor; at its authored x it also stood
  against the cliff. That, not the time scale, was "the QTE is not decelerating": the
  recall opened at swing start with the guardian 220 px away and nothing came. The three
  platform cells are gone, the guardian starts at x=170, and it now squares up to Ivo at
  every telegraph (a charge thrown the way it happened to face went into the wall).
- The recall opens on its cue: `recall_started` at 107 px with `trigger_distance` 110,
  `Engine.time_scale` 0.20 eased in, the ring and key above Ivo's head and the aura's
  rays around it (`f01_recall_aura.png`); Shift recalled the roll and lucidity opened.
- Drawing while the guardian sings is refused (instrument stays in). When the window
  opens the guardian's sheet slides away and Ivo's appears beside him, away from the
  guardian, pre-filled and dimmed with the [C] key blinking and the bar draining
  (`b02_answer_sheet_prompt.png`); C draws and the key goes; the answer lights the
  phrase note by note (`b04_answer_half.png` - the keyboard glyphs' lit art is subtle).
- The lesson moves: letterbox, title faded after 4 s, colour spreading, camera pushed
  in, petals falling in a region that was grey a minute earlier (`c02_lesson_6s.png`).
  Afterwards the village keeps its season: full colour, spring tint, petals
  (`c05_after_lesson_late.png`); Frost Edge before restoration shows snow hanging almost
  still at 0.2 (`f00_frost_weather.png`).
- Not judged: the tint's strength on a fully restored region (it is `tint_weight` x
  baseline; may read heavy), the aura's density, and the 2 s window in a live fight.

## Ratings rationale

- fun 4: the recall now lands where the blow is; the answer is a step the player can
  read; the Frost fight exists at all.
- fluidity 4: the slow eases, the sheets hand over, the lesson breathes.
- aesthetics 4: the lesson is a scene; the guardian clips are still idle frames.
