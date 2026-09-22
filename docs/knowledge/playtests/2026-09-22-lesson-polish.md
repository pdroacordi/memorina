---
id: playtests/2026-09-22-lesson-polish
type: playtest
title: The lesson holds its title and loses its sheet, creatures stop floating, and the grey is empty again
status: active
build: 4e48e99 + the round-6 fixes
area_tested: Bloom Hollow lesson (title, sheet, camera), Frost Edge and the village skies at several memory levels
tags: [lesson, cinematic, hud, weather, greyhush, camera, pause]
related: [playtests/2026-09-21-lesson-scene-and-answer, bugs/creature-pass-frozen-transform-floats-bodies, features/regional-weather, architecture/memory-runs-through-pause]
created: 2026-09-22
updated: 2026-09-22
ratings: { fun: 4, fluidity: 4, aesthetics: 4 }
screenshots:
  - screenshots/2026-09-22-lesson-polish/l_after_45.png
  - screenshots/2026-09-22-lesson-polish/w_frost_02.png
  - screenshots/2026-09-22-lesson-polish/w_frost_1.0.png
  - screenshots/2026-09-22-lesson-polish/w_village_08.png
---

## What was tested

A throwaway scene (deleted afterwards) restored the Bloom Guardian and then sat through
the WHOLE 59 s lesson track for the first time, logging `MemorinaHud.visible`, the frame,
the cinematic's card alpha, the dim, the camera zoom and `get_tree().paused` every second
or two. A second pass forced `MemoryField.baseline` to 0.2 / 0.5 / 1.0 in Frost Edge and
visited the village arena, to judge the sky at each memory level.

## Findings

- **The title card was never seen** because it faded 4.9 s in (a round-5 idea the user
  disliked on sight: "I liked it"). Card alpha logged 0.00 at every sample. It now holds
  for the whole track and leaves with the letterbox - `l_after_45.png` is 45 s in.
- **The sheet used to sit there for ~54 s**: a lesson's cues are at 0.5 - 5.5 s
  (placeholders) but the track runs 59 s, so the six notes were lit in the first six
  seconds and the sheet stayed for the rest. It now bows out 1.4 s after the last cue
  (`frame=false` from t+8 s onward) and the picture is the guardian, Ivo and the title.
- **Creatures floated** as the camera pushed in - the creature pass is a pausable
  mirror of the camera transform (own bug entry). Fixed; feet are on the floor at zoom
  1.15 in `l_after_45.png`.
- The push-in reached its target in 14 s and the shot then stopped moving for 45 s;
  `lesson_push_time` is now 45 s, so the frame is still closing in when the track ends.
- **The grey was full of specks.** At baseline 0.2 the old sky carried the full 140-flake
  winter emitter at full contrast. With `quiet_alpha` / `quiet_spread` and the memory
  sampled AT THE CAMERA (so the guardian's well of forgetting stills the sky above the
  arena), Frost Edge at 0.2 shows two faint flakes (`w_frost_02.png`) and the Bloom arena
  under its well is empty (`w_village_08.png`), while a remembered winter snows properly
  (`w_frost_1.0.png`).
- Tail verified for the first time: at `performance_finished` the HUD is hidden, the dim
  and bars ease out, the zoom returns to 1.0 and the tree unpauses.
- Not judged: whether 59 s of frozen world is the right length for a lesson at all - the
  beats (bars, title, colour, weather, push) now cover it, but the track is the only
  thing setting the duration.

## Ratings rationale

- fun 4: unchanged; this round was all presentation.
- fluidity 4: the lesson now has a beginning, a middle and an end that agree with each
  other; nothing hangs on screen past its purpose.
- aesthetics 4: the grey reads as empty again, which is the whole point of the greyhush.
