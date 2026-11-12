---
id: playtests/2026-11-12-story05-garden-rebuilt
type: playtest
title: STORY-05 garden rebuilt - the garden at the foot of the river's waterfall, a grass bank over a lake that reflects the characters, the tall fall close at the right into it, the lantern's light, a sky per flashback; flashbacks 1-5 run end to end, flashback 5's widest frame holds the waterfall and the hidden swap still hides
status: active
build: b9985614 + uncommitted garden rebuild
area_tested: "village_garden (c5..6, r-3..-2) and garden_past (105600, 12000): the five times of day in the past and the grey present (story05_garden_look_<n>.json); flashback 1 (story05_flashback_1.json, crossing at the fall, opening, guitar, leaving, return), flashback 4 (story05_flashback_4.json, night, the talk, the cut, the fray, the collapse) and flashback 5 (story05_flashback_5.json, the walk in from the trail's east stub, the colour with the song, the hidden swap, the seat, the widest frame, the gap); flashbacks 2 and 3 run to their returns."
tags: [story-05, flashback, garden, waterfall, lantern, light2d, backdrop, lake, reflection, playtest]
related: [architecture/story-05-playable-flashbacks, systems/props, systems/backdrops, systems/water, systems/world, playtests/2026-11-12-story05-flashback-1, playtests/2026-11-12-story05-flashback-4, playtests/2026-11-12-story05-flashback-5]
created: 2026-11-12
updated: 2026-11-12
ratings: { fun: 0, fluidity: 3, aesthetics: 4 }
screenshots:
  - 2026-11-12-story05-garden-rebuilt/t1_morning.png
  - 2026-11-12-story05-garden-rebuilt/t2_day.png
  - 2026-11-12-story05-garden-rebuilt/t3_afternoon.png
  - 2026-11-12-story05-garden-rebuilt/t4_night.png
  - 2026-11-12-story05-garden-rebuilt/t5_twilight.png
  - 2026-11-12-story05-garden-rebuilt/p0_present_grey.png
  - 2026-11-12-story05-garden-rebuilt/f1_pool_edge.png
  - 2026-11-12-story05-garden-rebuilt/f1_crossing.png
  - 2026-11-12-story05-garden-rebuilt/f1_opening_falls.png
  - 2026-11-12-story05-garden-rebuilt/f1_opening_wide.png
  - 2026-11-12-story05-garden-rebuilt/f4_night_wide.png
  - 2026-11-12-story05-garden-rebuilt/f4_for_you.png
  - 2026-11-12-story05-garden-rebuilt/f4_leaving.png
  - 2026-11-12-story05-garden-rebuilt/f5_swap_before.png
  - 2026-11-12-story05-garden-rebuilt/f5_swap_after.png
  - 2026-11-12-story05-garden-rebuilt/f5_swap_diff.png
  - 2026-11-12-story05-garden-rebuilt/f5_widest.png
  - 2026-11-12-story05-garden-rebuilt/f5_gap.png
  - 2026-11-12-story05-garden-rebuilt/f5_return.png
---

# STORY-05: the garden rebuilt

Read against the approved board (`tools/art/references/regions/garden_concept_v2.png`) and the user's notes: one pool, in front, full width; the tall fall close at the right, falling straight into it; the bank with the tree and swing, the stone, flowers and the lantern; "menos chão para os personagens ficarem mais próximos da água".

## What reads

- **The board's composition.** At zoom 1 on the bank the frame is the board's: the bank at about two thirds down, one earth row under the grass, the lake across the bottom quarter, the cliff and the fall close at the right with the foam on the water (`t4_night`, `f1_opening_wide`). The fall is drawn from the frame's top to the lake (`f1_opening_falls`).
- **Reflections.** The lake mirrors the bank's edge, the grass, the lantern post and its lit panes, the cliff and the fall (`t4_night`, `t3_afternoon`). Characters' reflections are short (one earth row of 32 px is mirrored first, then their legs), and torn into the lake's row bands.
- **Five times.** Morning (warm horizon, a pale sun, `t1_morning`), day (`t2_day`), late afternoon (orange, the low sun, the lantern faint, `t3_afternoon`), moonlit night (moon, stars, the lantern lighting the bank and the post's reflection, `t4_night`), twilight (violet and rose, `t5_twilight`). The present is the grey of the same place, the fall still (`p0_present_grey`).
- **The lantern.** Lit at night and twilight in four flat rings, faint at late afternoon, unlit by day and in the grey present. It warms Ivo when he stands by it (`f4_night_wide`): the light reaches the creature pass.
- **Flashback 1.** The crossing's column of colour comes down the fall into the lake, then spreads (`f1_crossing`); the opening's first shot is the foam at zoom 3 (`f1_opening_falls`), then her on the stone and both under the morning sky (`f1_opening_wide`). Talk, jam, leaving and the return to the same spot (local 1012, kneeling) as before.
- **Flashback 4.** Night; she stands at the bank's end by the fall with her back to him; he walks in from the west and stops behind her; the cut close on "For you." frames the two before the cliff (`f4_for_you`); the fray, the ribbon and the collapse (`f4_leaving`).
- **Flashback 5.** Ivo walks in from the trail's east stub (192 px/s), the colour rises with the song, the swap at local x 812: the camera centre is the same room-relative pixel before and after (909, 588). `f5_swap_diff` (channel sum over 15 between the last present frame and the first past frame) shows only the fall's strip phase, the lake's glints and bands, Ivo's idle frame and a few motes; the sky, ground, props, grass, grade and the lantern's light are the same. The pull-back reaches zoom 0.5: the whole room, the tree with her and the girl, the lantern and the waterfall, no void (`f5_widest`); the dusk deepens to the gap (`f5_gap`); the return kneels him where he stood (`f5_return`).

## Found and fixed during the run

1. **Alba hidden behind the cliff** (flashback 4, first run): the cliff's foot (`Contents/Falls`, z 10) draws over stagings (z -10) east of x 1068. Her figure, the flowers and the marks moved west of it (1040, 960-1040; Ivo behind her at 1000), the scene mirrored.
2. **The swap showed the lantern** (flashback 5, first run): the present lantern was unlit and the past's lit. The present lights it while flashback 5 is due, and its light follows the memory at the lantern, so the grey keeps it dark until the song's colour arrives.
3. **The widest frame showed bare edges** (flashback 5, first run): the layers covered only the zoom-1 travel. `Backdrop.widest_zoom` 0.5 grows the cover.
4. **The late-afternoon light was a yellow disc**: `LitDusk` at strength 0.3.
5. **The morning sun was off the garden's sky span** after the move east: `cut_backdrop.py` TIMES morning sun at art x 488 (was 440), redrawn.

## What does not read

- The sun of the morning and the moon show only in part of the camera's travel (the sky scrolls at 0.05).
- The lantern's rings are flat circles at window resolution, not game pixels; they read as glow, not as pixel art.
- Sound is not judged from frames.
- The timeline's walk to flashback 5's seat stopped at different places run to run (the release of a held key), so the timeline teleports Ivo beside the seat before Down.

## Verdict

The garden now reads as the board: the water in front, the fall close, the bank thin; every flashback plays through in it.
