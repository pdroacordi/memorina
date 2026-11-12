---
id: playtests/2026-11-12-story05-flashback-1
type: playtest
title: STORY-05 flashback 1 - the hum at the pool, the colour falling with the water into white, the pool then Alba on the stone, the crooked guitar beside her, the colour failing from the edges with her last, Ivo seated where he stood; the waterfall and the stone have no art yet, and the crossing's shot shows sky until the pool enters it
status: active
build: a366d1cf + uncommitted STORY-05 step 7 tree
area_tested: "village_garden (pool's east lip, x 2470 to 2374) with the Memorina owned: the lure, the CutsceneTrigger zone, flashback_1_crossing; the travel under white; garden_past: flashback_1_opening, free play (a teleport to the guitar), the talk flashback_1_guitar (take, three lines, the jam with the third mismatch, the last line), flashback_1 (the leaving); the travel back and flashback_1_returning."
tags: [story-05, flashback, cutscene, memory-bloom, greyhush, guitar, alba, playtest]
related: [architecture/story-05-playable-flashbacks, systems/cutscenes, systems/story, systems/music]
created: 2026-11-12
updated: 2026-11-12
ratings: { fun: 0, fluidity: 3, aesthetics: 3 }
screenshots:
  - screenshots/2026-11-12-story05-flashback-1/01_pool_edge.png
  - screenshots/2026-11-12-story05-flashback-1/c05_crossing.png
  - screenshots/2026-11-12-story05-flashback-1/c07_crossing.png
  - screenshots/2026-11-12-story05-flashback-1/o02_opening.png
  - screenshots/2026-11-12-story05-flashback-1/o06_opening.png
  - screenshots/2026-11-12-story05-flashback-1/o10_opening.png
  - screenshots/2026-11-12-story05-flashback-1/p01_at_guitar.png
  - screenshots/2026-11-12-story05-flashback-1/g04_line1.png
  - screenshots/2026-11-12-story05-flashback-1/j01_laugh.png
  - screenshots/2026-11-12-story05-flashback-1/l03_leaving.png
  - screenshots/2026-11-12-story05-flashback-1/l06_leaving.png
  - screenshots/2026-11-12-story05-flashback-1/l08_leaving.png
  - screenshots/2026-11-12-story05-flashback-1/r00_return.png
  - screenshots/2026-11-12-story05-flashback-1/r05_return.png
---

## What was tested

`tools/playtest/scripts/story05_flashback_1.json` (game.tscn, en, owned sword and Memorina, Ivo at (2470, -490)): Left 0.5 s into the pool-edge zone; the crossing (9 s); the travel; the opening (11.6 s); a teleport to the guitar (103930, 12270); Up; the take; Z through three lines; six notes (E, wrong, E, wrong, wrong, D: the third mismatch at the fifth press); silence; Z on the last line; the leaving; the return. Two runs: the second after moving the crossing's and the opening's first frames down to the pool (offsets -96 to -56 and -64 to -20).

Read against `docs/design/drafts/camada_pessoal.md` §2, flashback 1's Cinema line.

## Findings

What reads:
- **The call.** The garden is grey at 0 (`01_pool_edge`); the bars come in and the frame closes on the pool. The hum and the duck cannot be judged from frames; the log shows Ivo blocked from the zone entry to the crossing's end.
- **The crossing comes from the water.** A column of colour grows from the top of the frame down into the pool (`c05_crossing`), then spreads over the screen, and white rises over it (`c07_crossing`). Ivo is still throughout; no slow motion.
- **The memory opens on a detail.** The first frame after the white is the pool at zoom 3 in colour (`o02_opening`), then the frame moves to Alba on the stone, her back to Ivo (`o06_opening`), then widens to both of them (`o10_opening`). The thin bars stay while he walks (`p01_at_guitar`).
- **The guitar.** Up at the leaning guitar starts the talk; he walks to her and the lines show her plate and portrait (`g04_line1`); in the jam he holds the guitar beside her (`j01_laugh`). Six presses, a 2.5 s silence, then "There. Crooked, but together."
- **The leaving.** The frame closes on her at zoom 2 (`l03_leaving`), the grey eats the frame from the edges and she is the last colour (`l06_leaving`), then all is grey with her voice still going (`l08_leaving`), and the cut lands on the next bar line.
- **The return.** Ivo is back at (2461.4, -480), facing west as he stood, seated for 1.4 s, then standing (`r00_return`, `r05_return`). The music is silent until the scene ends (`flashback_director_test`).

What does not read:
- **No waterfall.** The garden has no waterfall art: the "water falling" is a column of colour over an empty sky, and the opening's detail is the pool. The Cinema line's "a cachoeira parada no ar" cannot be seen.
- **No flat stone.** Alba sits on the grass at x 816; nothing under her reads as a stone.
- **The keep rectangle.** The colour Alba keeps is a hard-edged rectangle while it shrinks (`l06_leaving`); the draft asks for the memory dither eating inward. A softer edge (more feather or a circle) is a tuning choice for the user.
- **The laugh.** The stand-in is her singing loop at 2.5x for 1.2 s. A frame cannot show it, and there is no laugh sound.
- **The take.** Ivo walks to her empty-handed (no carrying clip); the guitar appears in his hands when the jam starts.
- **The kneel.** There is no kneel clip; the seated loop stands in.
- **Sound.** The hum, the duck, the song's fade-in, the detuned strings, the muffle and the 1 s of silence are not judged here: screenshots carry no audio.

## Ratings rationale

- fun 0: not judgeable from frames; the beat asks for no skill by design.
- fluidity 3: every hand-off ran in order on both runs (trigger, travel, opening, talk, beat, leaving, travel, returning), and Ivo returned to the same place and facing. The take's 3.8 s walk across the garden is long.
- aesthetics 3: the colour against the grey works, and the leaving reads. The missing waterfall and stone weaken the first and last images the Cinema line names.

## Revisited

The garden was rebuilt the same day (a bank over a lake, the fall at the right, a sky per flashback): `playtests/2026-11-12-story05-garden-rebuilt`. The timeline was moved to the new room; the positions above are the old room's.
