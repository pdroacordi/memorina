---
id: playtests/2026-11-12-story05-flashback-3
type: playtest
title: STORY-05 flashback 3 - Up held raises the fallen swing step by step with colour up the rope, letting go lets it fall back, at the top it swings once and white; the past at late afternoon, Alba on the swing, four pushes between her lines, the swing stopping by itself, the camera holding on the two as the colour fails, Ivo kneeling back by the hanging swing
status: active
build: 2499b6d0 + uncommitted STORY-05 step 9 tree
area_tested: "village_garden with flashback 3 due (Memorina, Frost and Bloom restored, flashbacks 1-2 seen): Creak3, the talk flashback_3_swing, Raise3 (SwingRaiseBeat over HoldRise, a hold, a release, a hold to the top), flashback_3_crossing, the travel under white; garden_past: the Light staging, flashback_3_opening, four flashback_3_push_<n> talks (SwingPushBeat), the let-go beat, flashback_3 (the leaving); the travel back and flashback_3_returning."
tags: [story-05, flashback, cutscene, memory-bloom, swing, held-up, alba, camera, playtest]
related: [architecture/story-05-playable-flashbacks, systems/cutscenes, systems/input, playtests/2026-11-12-story05-flashback-2, bugs/a-flashback-return-glides-the-frame-from-the-past]
created: 2026-11-12
updated: 2026-11-12
ratings: { fun: 0, fluidity: 3, aesthetics: 3 }
screenshots:
  - screenshots/2026-11-12-story05-flashback-3/r1_rise.png
  - screenshots/2026-11-12-story05-flashback-3/r2_rise.png
  - screenshots/2026-11-12-story05-flashback-3/r3_recede.png
  - screenshots/2026-11-12-story05-flashback-3/r6_rise.png
  - screenshots/2026-11-12-story05-flashback-3/r7_top.png
  - screenshots/2026-11-12-story05-flashback-3/c02_crossing.png
  - screenshots/2026-11-12-story05-flashback-3/c05_crossing.png
  - screenshots/2026-11-12-story05-flashback-3/o00_opening.png
  - screenshots/2026-11-12-story05-flashback-3/o03_opening.png
  - screenshots/2026-11-12-story05-flashback-3/p1_push.png
  - screenshots/2026-11-12-story05-flashback-3/p2_line2.png
  - screenshots/2026-11-12-story05-flashback-3/l03_leaving.png
  - screenshots/2026-11-12-story05-flashback-3/l05_leaving.png
  - screenshots/2026-11-12-story05-flashback-3/l07_leaving.png
  - screenshots/2026-11-12-story05-flashback-3/b00_return.png
  - screenshots/2026-11-12-story05-flashback-3/b03_return.png
---

## What was tested

`tools/playtest/scripts/story05_flashback_3.json` (game.tscn, en, sword and Memorina, Frost and Bloom restored, `flashback_1` and `flashback_2` seen, Ivo at (1550, -490), 42 px west of the fallen swing): Up held from 1.0 s to 2.3 s, released 0.7 s, held again to 5.6 s; the crossing; the travel; the opening; four Up presses at the swing with Z through the lines; the leaving; the return. Four runs: the second after softening the rope's bloom, warming the light and closing the opening's first shot to zoom 4; the third after the camera cut on an opaque end; the fourth after the snap landed the talk's ease.

Read against `docs/design/drafts/camada_pessoal.md` §2, "3. O pedido para não buscar ajuda fora", its Cinema line.

## Findings

What reads:
- **The rise.** Each 0.5 s held lifts the seat a step with its two ropes climbing, and a soft column of colour climbs with them out of the grey (`r1_rise`, `r2_rise`). Released, it sinks a step (`r3_recede`, the log at 2.9 s: Ivo free of the block, standing). Held again it reaches the branch (`r6_rise`), hangs there in colour and swings once by itself (`r7_top`, tilted east).
- **The crossing.** Bars in, the frame on the branch; the colour spreads from the rope over the garden (`c02_crossing`) and white covers it (`c05_crossing`).
- **Late afternoon.** The past is warm orange (the `LateAfternoon` overlay, a multiply and an orange glow from the west). The opening's first shot is her on the seat at zoom 4 (`o00_opening`), then both at zoom 1 under the tree (`o03_opening`).
- **The pushes.** Each Up plays Ivo's push and the swing goes out east with her on it (`p1_push`); he stands for her line while it swings and dies down (`p2_line2`). The four talks came in order.
- **The stop.** After "Stay. We'll stay. I'll get better here." the swing settles by itself within the held frame on the two (`l03_leaving`, still); the colour fails from the edges, the keep circle last on her and the swing (`l05_leaving`, `l07_leaving`).
- **The return.** Ivo kneels where he stood, the swing hanging from the branch now, grey (`b00_return`), then stands (`b03_return`).

What does not read:
- **Her hands on the rope.** The art has no hands-on-rope clip: the close shot is her seated frame on the seat. A stand-in.
- **The raise has no gesture.** Ivo stands still while he raises it (no hoist clip); the rope's colour carries the action. A stand-in.
- **Sound.** The creak (`rope_creak.wav`, synthesized), the silence of the stop and the music are not judged from frames.

Fixed during the runs (`bugs/a-flashback-return-glides-the-frame-from-the-past`): on the first run the return opened framed on the pool, 840 px east of Ivo, and slid to him over 3 s. The leaving's recorded end eased the camera rig from the past towards Ivo while the travel moved him; and the push talk's zoom 2 release was still easing when the black cleared.

## Ratings rationale

- fun 0: not judgeable from frames; the hold-to-raise read as an action in the log and frames (it recedes on release).
- fluidity 3: every hand-off ran in order on all runs (talk, HELD_UP beat, crossing beat, travel, opening, four push talks, let-go beat, leaving, travel, returning), and Ivo returned to the same step and facing.
- aesthetics 3: the rope of colour, the warm afternoon, the pushes and the stop read; the hands and the hoist are stand-ins.
