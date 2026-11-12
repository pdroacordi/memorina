---
id: playtests/2026-11-12-story05-flashback-4
type: playtest
title: STORY-05 flashback 4 - the ribbon hangs still in the grey, a short cut to night; Alba at the pool's edge with her back turned, Ivo's two lines and her turn in a wide frame, a hard cut close on "For you.", her edge frays once, she gives him the ribbon and the colour fails in silence; Ivo kneels back with it
status: active
build: 7156b8d6 + uncommitted STORY-05 step 10 tree
area_tested: "lake_glacier with flashback 4 due (Memorina, Frost, Bloom and Autumn restored, flashbacks 1-3 seen): the still ribbon, flashback_4_ribbon_frost, flashback_4_crossing, the travel under black; garden_past: the Night light, flashback_4_opening, flashback_4_alba (near, silence and turn beats), flashback_4_for_you (cut frame), flashback_4 (fray, ribbon, collapse); the travel back and flashback_4_returning."
tags: [story-05, flashback, cutscene, fray, corruption-edge, alba, camera, night, playtest]
related: [architecture/story-05-playable-flashbacks, systems/cutscenes, systems/dialogue, systems/creatures, playtests/2026-11-12-story05-flashback-3]
created: 2026-11-12
updated: 2026-11-12
ratings: { fun: 0, fluidity: 3, aesthetics: 3 }
screenshots:
  - 2026-11-12-story05-flashback-4/01_ribbon_still.png
  - 2026-11-12-story05-flashback-4/c02_crossing.png
  - 2026-11-12-story05-flashback-4/c04_crossing.png
  - 2026-11-12-story05-flashback-4/o00_opening.png
  - 2026-11-12-story05-flashback-4/o04_opening.png
  - 2026-11-12-story05-flashback-4/t1_line1.png
  - 2026-11-12-story05-flashback-4/t2_look.png
  - 2026-11-12-story05-flashback-4/t4_typed.png
  - 2026-11-12-story05-flashback-4/f_fray_strip.png
  - 2026-11-12-story05-flashback-4/l01_leaving.png
  - 2026-11-12-story05-flashback-4/l03_leaving.png
  - 2026-11-12-story05-flashback-4/l05_leaving.png
  - 2026-11-12-story05-flashback-4/l07_leaving.png
  - 2026-11-12-story05-flashback-4/b00_return.png
  - 2026-11-12-story05-flashback-4/b04_return.png
---

## What was tested

`tools/playtest/scripts/story05_flashback_4.json` (game.tscn, en, Frost, Bloom and Autumn restored, `flashback_1..3` seen, Ivo at (5800, -1650) by the lake_glacier ribbon): Up at the ribbon; the crossing; the travel; the opening; Left 0.62 s toward her; Up; Z through four lines; screenshots every 0.04 s for 0.6 s after the last Z; the leaving; the return. Five runs: the first two missed her reach and the typing; the third had the close at zoom 3 with the box over their heads and the moonlight greying her skin; the fourth and fifth closed at zoom 2 and lightened the moonlight.

Read against `docs/design/drafts/camada_pessoal.md` §2, "4. A insistência, e ela cedendo por amor", its Cinema line.

## Findings

What reads:
- **The still ribbon.** The bow hangs on its twig in the grey pocket, its first frame held (`01_ribbon_still`); Ivo takes it (`c02_crossing`) and the screen goes black in 0.3 s (`c04_crossing`). No colour, no white.
- **Night.** The past opens on the falling water at zoom 3 (`o00_opening`) and pulls back to the wide frame: the pool, the waterfall, her at the east lip facing the water, Ivo far off (`o04_opening`). Cold blue, the sky and water readable.
- **The talk.** The frame stays wide through Ivo's two lines, the silence and her turn (`t1_line1`, `t2_look`: she faces out of the picture, toward him).
- **The cut.** "For you." opens on a hard cut to zoom 2 centred on her, Ivo at the frame's right (`t4_typed`; the log's camera centre at her x, 104756, from the first frame).
- **The fray.** `f_fray_strip` (14 frames 0.04 s apart from the closing Z): two frames with the box, then 8 frames (about 0.32 s) of her edge breaking into the dithered fringe, then plain art for the rest of the run. Once: no other frame of the run frays, and `test_only_flashback_4_frays_her_once` holds that no other scene can. It composites in the root canvas under the Night overlay with no halo and no grey: only her silhouette's edge moves, the ground and the water behind are untouched.
- **The ribbon.** She faces him and holds it out (`l01_leaving`), he holds it (`l03_leaving`); the grey closes on the two at the close frame (`l05_leaving`, `l07_leaving`).
- **The return.** Ivo kneels on the lake ledge where he stood (`b00_return`, the grey pocket still fading), then holds the ribbon (`b04_return`).

What does not read:
- **The wrist.** He holds the ribbon in his hand (`ivo_ribbon`); no tie-on-wrist clip. A stand-in.
- **Ivo under the moon.** Ivo draws above the Light overlay, so he stays warm while she is blue, as he stays unlit in flashback 3's afternoon.
- **Sound.** The water (`waterfall_night.wav`, synthesized), its stop at the cut and the silent leaving and return are not judged from frames; the data holds them (the visit's cue has no stream, the water is gated on `flashback_4_alba` unheard).
- **The collapse at zoom 2.** The keep circle's ring is visible on the sky as it shrinks (`l05_leaving`), as in flashbacks 2 and 3.

## Ratings rationale

- fun 0: not judgeable from frames.
- fluidity 3: every hand-off ran in order on the last runs (ribbon talk, crossing beat, travel, opening, talk with three beats, auto-started close talk, leaving beat, travel, returning), and Ivo came back to the same ledge, facing west.
- aesthetics 3: the still ribbon, the night, the wide talk and the single cut and fray read; the wrist and the sound are stand-ins.

## Revisited

The garden was rebuilt the same day (a bank over a lake, the fall at the right, a sky per flashback): `playtests/2026-11-12-story05-garden-rebuilt`. The timeline was moved to the new room; the positions above are the old room's.
