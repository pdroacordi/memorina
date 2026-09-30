---
id: playtests/2026-09-23-lake-and-water-hazard
type: playtest
title: Round two of generated water - the lake in front of the path, the pool/lake seam, and Ivo not swimming
status: active
build: 7cfe1fe (plus an uncommitted working tree that does not touch water - guardian .tres tuning, a brute_shadow.tscn line, a game.tscn editor resave; every timeline teleports Ivo)
area_tested: Woods lake (x≈1552), Downtown lake x -1376..32 across DowntownWell, the lake/pit-pool seam at x 32 grey and mid-FREEZE, the water hazard (sink, fade, respawn) in the pit and through thawing ice
tags: [water, lake, reflection, glints, greyhush, hazard, respawn, freeze, camera]
related: [playtests/2026-09-23-generated-water, bugs/camera-zoom-out-shows-past-room-bounds, bugs/lake-clock-runs-at-the-fastest-memory-across-the-room, bugs/splash-rings-the-alternating-column-mode, bugs/water-reflection-fades-at-side-screen-edges, architecture/water-is-world-art-reflecting-two-passes]
created: 2026-09-23
updated: 2026-09-23
ratings: { fun: 3, fluidity: 3, aesthetics: 3 }
screenshots:
  - screenshots/2026-09-23-lake-and-water-hazard/01_woods_lake_running.png
  - screenshots/2026-09-23-lake-and-water-hazard/02_woods_reflection_300.png
  - screenshots/2026-09-23-lake-and-water-hazard/03_perforated_glints_at_memory_edge_300.png
  - screenshots/2026-09-23-lake-and-water-hazard/04_seam_grey_300.png
  - screenshots/2026-09-23-lake-and-water-hazard/05_seam_mid_pulse.png
  - screenshots/2026-09-23-lake-and-water-hazard/06_seam_colour_300.png
  - screenshots/2026-09-23-lake-and-water-hazard/07_hazard_beat.png
  - screenshots/2026-09-23-lake-and-water-hazard/08_zoom_out_shows_ground_under_water.png
---

## What was tested

This round covers commits 1c5117f..7cfe1fe: the lake shader, tile-painted water, and
water as a hazard. The runs used Godot 4.7.2, windowed, at 1280×720, which is 2× the
game. The "300%" crops are nearest-neighbour upscales.

- Existing timelines: `water_reflection.json`, `water_hazard_fall.json`,
  `water_freeze_crossing.json`, `water_freeze_growth.json`.
- New, `water_downtown_lake_walk.json`: Ivo starts at x -1100 in remembered water
  (memory 0.8), runs right into `DowntownWell` (memory about 0.1), then stands.
- New, `water_grey_lake_still.json`: Ivo stands on the Downtown bank. The spawn at x 120
  drops him in the pit, and he respawns on the bank before the first shot. Screenshots at
  2.5, 5, 7.5, 10 and 12.5 s, diffed pixel by pixel.
- A scratch timeline (not committed) re-ran FREEZE twice with shots every 0.1 s over the
  zoom release, to reproduce the bottom strip.

## Findings

**Verified fixed since the last round** (`playtests/2026-09-23-generated-water`)
- The splash no longer reads as a needle and then a comb. It is a small crest with a
  trough on each side, spreading out and settling (`07_hazard_beat.png`, t 3.90 and
  4.20; still settled 10 s later in the stationary run).
- There is no navy seam at the side screen edges. At zoom 1.5 the rightmost columns
  match the interior (36..44 green-grey, no step to navy).
- The lake clock (`bugs/lake-clock-runs-at-the-fastest-memory-across-the-room`): the
  grey Downtown lake was pixel-identical across 10 s of standing (x 0..400 on screen,
  every lake row). The only changing pixels were the pit pool's swell and the brute. At
  the old room-wide 0.8 rate the shore line's dashes would have re-rolled several times
  in that window. The evidence is consistent with the per-column clock. It does not
  prove the clock, because rates this slow barely re-roll in 10 s anyway.

**The lake: does it read as water in front of the path?**
- **Mostly yes where it is remembered, and best in colour.** Mid-FREEZE in Downtown
  (`05_seam_mid_pulse.png`) it is the closest yet to the reference: light sky reflected
  just under the far shore, darkening to navy toward the viewer, glints, and Ivo's
  reflection hanging from his feet and breaking into slats at depth. It reads as a lake
  in front of the path.
- **In the Woods it reads as dark water, but not yet as "the scene mirrored"**
  (`01_woods_lake_running.png`). The lake is 56 world px deep, so it mirrors the 56 px
  above its axis. That is the flat dark underbrush band, (58, 69, 53) before the tint
  and about (44, 56, 48) after. The trees and the sky never enter it. What sells it as
  water is Ivo's reflection and the glints, not the mirrored forest. The previous round
  found the same thing on the strip. Painting the lake to the room's bottom did not
  change it, because the camera frames Ivo low and shows only about 52 px of lake.
- **The torn reflection works** (`02_woods_reflection_300.png`). The feet meet the shore
  line, the legs stay whole in the thin rows near the shore, and the torso and head
  slide apart in taller bands lower down, as the reference does.
- **The reflection is checkerboarded across whole depth bands** (`02`, `06`). `wc_band`
  dithers the continuous depth between every pair of ramp entries (the 5-entry
  `lake_reflection_ramp` over `depth_band_px` 10). The reflection's tint and its
  posterised strength therefore alternate pixel by pixel through most of the lake. Every
  sampled column alternates rows, for example (44,56,48)/(41,51,46), then
  (36,47,48)/(41,51,46), down the Woods lake. This is the "whole reflection becomes a
  checkerboard" look that `wr_gate` was written to avoid. It arrives through the ramp
  instead of the gate. The reference's rows are flat colours. Try flat bands with a 1-row
  dithered seam, or dither only the body ramp and not the reflection's.
- **Glints: density is reasonable, brightness is right, and they perforate as memory
  fades.** Measured, as pixels more than 35 above their row's median luminance: 4 to
  6 % in the top 20 rows below the shore, falling to about 1.5 % past 30 rows. So
  "thinning toward the viewer" is really there. The alpha of 0.45 lifts about (38,48,43)
  to about (103,120,114). That is well under the shore line (155..178), so the line
  still reads as the lightest thing on the water. In the memory 0.15..0.6 band at the
  well's edge (`03_perforated_glints_at_memory_edge_300.png`), each dash is gated per
  pixel on the Bayer grid, so a 6 px dash turns into `. . .`, a dotted line. It reads as
  Morse code, not as glints thinning out. Gating once per dash (one Bayer lookup at the
  dash's first pixel) would make fading water show fewer glints rather than broken ones.
- **The shore line nearly vanishes in colour.** Mid-pulse, the lake's line is
  (157,186,210) over a reflected sky at (104,145,200) directly under it. The pool's ice
  line beside it is (205,229,246). The "straight light line" that anchors the reference
  is the weakest element exactly where the lake looks best. In grey (178 over 89) and
  in the Woods (165 over 44) it reads fine.
- **Grey water is right.** At memory 0.1 the lake is a flat grey plate: the light line
  on top, a dithered depth darkening from 89 to 61, no reflection, no glints, and no
  motion across 10 s. That is the "still sheet with only its light line" the brief asked
  for. The line has one static 16 px gap (`LINE_GAPS`) near the pit, which is harmless.

**The seam at x 32**
- Grey (`04_seam_grey_300.png`): both waterlines sit on the same row (304), so the line
  continues across. But the lake's line is dimmer (178 vs 194) and broken by dashes,
  and below it the pool's body is lighter (110 vs 89 at row 305). The seam is a hard
  vertical cut that lines up with the pit's edge above. It reads as the pit wall carrying
  on down into the water.
- Mid-pulse (`05`, `06`): two different materials butt together on one row. The lake is
  torn reflection and glints with a faint line; the pool is a flat plate with a bright
  ice line. It reads as two waters, not one continuous body, and not as a lake passing in
  front of the pit. This is a model clash rather than a bug: a plane in front of the path
  meets a cross-section inside the pit. It needs a design call. Options: a strip of bank
  between them, the pool taking the lake's shading where they meet, or the pit's water
  being lake too.
- The pulse boundary crossing the lake is clean. Navy stipples out to grey on the Bayer
  grid, and the glints stop at the edge (`05`).

**The water hazard** (`07_hazard_beat.png`; the times are the harness's `t`)
- The sequence is legible: airborne at 3.05; the pink hurt flash at 3.20 with his legs
  in the water; at 3.40 he is veiled to the chin with the screen at about 40 % dark; at
  3.60 almost black; at 3.90 he is back on the bank with the screen half clear; at 4.20
  fully clear. The FREEZE run matches: the pink flash on thawing ice at 10.25, black at
  10.75, back on the bank at 11.25, not on the ice.
- **Pacing (an inference from timing, not a feel judgement):** contact to clear is about
  1.0 s. That is `Fade.DURATION` 0.5 s out, two physics frames, then 0.5 s in. The fade
  starts on contact, so the sink (40 px/s, about 20 px before black) happens under a
  darkening screen. It is readable in exactly one captured frame (3.40). The respawn
  itself is well hidden: the camera snap lands behind the black and nothing slides. If
  the sink should register as a beat of its own, try holding 0.2..0.3 s before
  `to_black()`. A human needs to confirm whether 1 s feels punchy or abrupt.
- The respawn point is correct: the last firm ground, about 15 px back from the pit
  edge, facing the pit. A player still holding right walks straight back in. That is
  intended as far as I know; there is no i-frame protection from water.
- **The 1 HP cost is invisible.** There is no health HUD in the game (`scenes/ui/` has
  none), so "at 1 HP it kills" cannot be anticipated by a player. It is outside the
  water work, but water is the first thing that spends HP outside a fight.

**Bug**
- **The zoom-out shows past the room's bottom** (filed:
  [bugs/camera-zoom-out-shows-past-room-bounds](../bugs/camera-zoom-out-shows-past-room-bounds.md),
  `08_zoom_out_shows_ground_under_water.png`). For about 0.2 s after every song in
  Downtown, a dark line of ground tile 1..3 game px tall shows under the lake and the
  pool. It reproduced in 3 of 3 runs. The camera clamps in physics with a zoom the idle
  tween then changes. The bug predates the lake; the lake is what makes it visible.

**Could not be judged from stills**
- Whether the glints shimmer or crawl, and whether the band slide reads as ripples or as
  jitter. Everything above about the lake's motion is a count or a diff, not a look at
  the motion.
- The sound of the fall, and whether 1 s of fade feels fair.

## Ratings rationale

- **Fun 3 (low confidence, inferred).** Water now matters: a fall costs something, the
  FREEZE crossing ends in a real fall, and the respawn is fair (firm ground, never ice).
  Whether that is tense or merely punitive depends on feel, and on the invisible HP.
  Needs a human.
- **Fluidity 3 (inferred from timing).** The hazard beat is clean and fast, with no
  visible cut. But the sink only registers under the fade, and the bottom strip shows on
  every post-song zoom-out. Camera and fade feel cannot be seen in stills.
- **Aesthetics 3, a stronger 3 than last round.** The splash and the edge seam are fixed,
  grey water is exactly right, and in colour the lake finally reads as a lake. It is held
  back by the checkerboard over the reflection, the dotted glints at memory edges, the
  shore line lost against the sky reflection, the two-material seam at the pit, and a
  Woods lake that still mirrors only underbrush.
