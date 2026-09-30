---
id: playtests/2026-09-23-generated-water
type: playtest
title: Generated water - the reflection strip, a splash in grey water, and the FREEZE crossing from growth to fall
status: active
build: 20597f0 (every frame re-shot on it; the first pass on 224d721 agrees)
area_tested: Woods reflection strip (x≈1552), Downtown pit pool (x 32..224, memory ≈0.1), FREEZE on that pool
tags: [water, reflection, splash, freeze, ice, greyhush, pixel-art, caustics]
related: [bugs/splash-rings-the-alternating-column-mode, bugs/water-reflection-fades-at-side-screen-edges, bugs/water-swell-flattened-by-spread, bugs/ice-front-leaps-dead-columns, architecture/water-is-world-art-reflecting-two-passes, architecture/memory-gated-height-field]
created: 2026-09-23
updated: 2026-09-23
ratings: { fun: 3, fluidity: 3, aesthetics: 3 }
screenshots:
  - screenshots/2026-09-23-generated-water/01_reflection_strip.png
  - screenshots/2026-09-23-generated-water/02_reflection_ivo_400.png
  - screenshots/2026-09-23-generated-water/03_reflection_edge_seam_400.png
  - screenshots/2026-09-23-generated-water/04_splash_needle_then_comb.png
  - screenshots/2026-09-23-generated-water/05_grey_caustic_speckle_400.png
  - screenshots/2026-09-23-generated-water/06_ice_growth_front_400.png
  - screenshots/2026-09-23-generated-water/07_pulse_edge_grey_vs_colour.png
  - screenshots/2026-09-23-generated-water/08_thaw_and_fall.png
---

## What was tested

Five timelines in `tools/playtest/scripts/`, run windowed with Godot 4.7.2:

- `water_reflection.json`: the strip reflecting the forest and Ivo running, then the
  Memorina focus zoom to 1.5.
- `water_splash_crest.json`: Ivo jumps into the grey pit pool, then the pool 3 s later.
- `water_freeze_crossing.json`: FREEZE on the bank, walk onto the ice at 7.6 s, stand,
  thaw.
- `water_splash_closeup.json` (new this session): the same splash with screenshots every
  0.1 s from 3.0 to 4.2 s, then at 4.6, 5.2, 6, 8 and 10.5 s.
- `water_freeze_growth.json` (new): the FREEZE phrase with screenshots every 0.15 s from
  4.4 to 7.25 s, to catch the pulse lighting and the ice growing. The given crossing
  timeline starts capturing after both have happened.

The first pass ran on 224d721. Commit 3f64f90 then landed (a new caustic memory gate,
the surfaces at `z_index` 50, and a rate refresh), so all five were re-run on 20597f0.
Every finding below holds on HEAD. Screenshots are 1280×720, which is 2× the 640×360
game, so the 400% crops are nearest-neighbour upscales of the PNGs.

## Findings

**What works (pixel discipline is strong)**
- The waterline is stepped per 2 px column in 1 px steps, and there is exactly one light
  top line. No sub-pixel softness shows anywhere in the water
  (`02_reflection_ivo_400.png`, `06_ice_growth_front_400.png`).
- The reflection is crisp and blocky, and it is cut into 2-row bands that slide 1 px. That
  matches the reference (`02_reflection_ivo_400.png`). Ivo's running reflection tracks
  him, and it stays 1:1 at zoom 1.5 (feet to head measured the same on the body and in
  the reflection), which confirms the derivative-scaled world-space mirror.
- Grey water at memory 0.1 is a grey plate with the lighter top line and two stippled
  depth bands. There is no reflection: Ivo is airborne over the pool at t 3.0 and nothing
  shows under him, because 0.1 is below `reflect_memory_low` 0.15.
- The grey swell still steps slowly, so grey water is not frozen, as decided.
- Submerged, Ivo is veiled dark and cool. His head crossing the waterline dithers over
  about 4 rows, and the top line is correctly hidden behind it.
- FREEZE: the ice grows from the bank where the song was played toward the far bank.
  The front is a pale Bayer stipple ahead of the solid ice, at roughly 130 px/s in this
  pulse (from positions frame to frame; `06_ice_growth_front_400.png`).
- Solid ice reads clearly: a near-white top line and a pale 6 px band over deep navy.
  Ivo's reflection carries on under it, so it reads as clear ice.
- The thaw starts at the origin and runs forward at about 48 px/s (front at about 40 px
  at 8.75 s, 65 px at 9.25 s). The melting stretch breaks into slush and then water with
  coarse 3 px caustic bands. **The player really falls** (`08_thaw_and_fall.png`): the
  rear foot stands on melting ice while the front foot is still on solid, then he drops
  through. In run 1 the legs are through at 10.25 s; on HEAD he is already through at
  9.75 s. That is about 0.5 s of run-to-run variance, and both runs fall earlier than the
  ~10.75 s the brief expected.
- The pulse boundary crosses the pool cleanly: navy with ice inside, grey outside
  (`07_pulse_edge_grey_vs_colour.png`).

**Problems**
- **Bug, the splash crest is a needle and then a comb**
  ([bugs/splash-rings-the-alternating-column-mode](../bugs/splash-rings-the-alternating-column-mode.md),
  `04_splash_needle_then_comb.png`). At t 3.4 to 3.5 a 2 px wide spike about 5 px tall
  stands on the line. From 3.8 to 5.2 it becomes alternating 1 px teeth, and the zig-zag
  chop is still there at 10.5 s. It never reads as a crest or mound. Confirmed with a
  headless replica of the springs.
- **Bug, navy seam at the screen's side edges on the strip**
  ([bugs/water-reflection-fades-at-side-screen-edges](../bugs/water-reflection-fades-at-side-screen-edges.md),
  `03_reflection_edge_seam_400.png`, frames `02_zooming` and `03_zoom_1_5`). The last 12
  game px before the right edge stipple from green-grey (34, 42, 38) to navy (21, 25, 33).
- **The strip mirrors only the underbrush, not "the whole scene"**
  (`01_reflection_strip.png`). The strip is 39 px tall, so it reflects the 40 px above
  its axis. That is the uniform dark band of forest floor, and after the reflection ramp
  it comes out at (44, 54, 47). Only Ivo is ever visible in it; the trunks, the treeline
  and the sky never appear.
- **The strip is not cool and barely darkens with depth.** The body is (44, 54, 47)
  against dirt at (38, 39, 35), so the water separates from the ground almost only by
  its top line. The cause: `reflection_strength` 1.0 with ramp alpha 255 lets the
  reflection replace the navy `strip_body_ramp` everywhere, and the ramp's depth
  darkening multiplies an already-dark green.
- **The strip is placed as a window in the dirt.** It sits 8 game px below the grass and
  its ends are hard vertical cuts (frame 00, x 128). It reads as an inset panel rather
  than water in front of the bank.
- **Caustic speckle in grey water** (`05_grey_caustic_speckle_400.png`, also present
  after 3f64f90's gate change). At memory 0.1, isolated light pixels sit 2 to 8 px under
  the line. The slow clock keeps them nearly static. This is the high-frequency texture
  on grey that CLAUDE.md rules out ("the grey is empty").
- **Out of scope for water, noted for the greyhush owner:** the pulse's leading ring and
  its dark halo are drawn as a smooth, soft gradient in `07_pulse_edge_grey_vs_colour.png`,
  not stepped or dithered.

**Not verifiable in this build or with stills**
- The crest frozen for ever at memory exactly 0: no water sits at 0. With the current
  impulse, that crest would be a 2 px notch with shoulders (an inference).
- "Hardens before it looks solid": nothing splashed into the crystallising zone. A
  timeline that drops Ivo onto the stipple front would test it.

**Tuning to try (each needs a look afterwards)**
- `strip_reflection_ramp.png` alpha 255 / 200 / 200 / 110, which posterises to
  1 / .67 / .67 / .33 at `reflect_levels` 4. The navy body then bleeds in with depth,
  making the water darker and cooler toward the bottom. Optionally cool its RGB to about
  (170,190,236) / (150,168,224) / (128,146,210) / (108,124,196).
- Showing the treeline needs one of two things: a much taller strip, or a vertical
  reflection-compression parameter (a new feature, for the architect or design). Also:
  put the strip flush under the grass and extend it past the room's visible width, so no
  end is ever in view.
- Grey caustics: gate them with the reflection's own `fade` (nothing below
  `reflect_memory_low`) instead of a per-pixel memory dither. There is no tuning-only
  knob for this.
- Crossing tension (inferred): Ivo walks about 150 px/s, so the 192 px pool takes about
  1.3 s, while the thaw needs 1.5 s + 192/48 s. On this pool the crossing is very
  forgiving. For a real timed crossing, try `thaw_speed` 48 → 64 to 80 or `thaw_delay`
  1.5 → 1.0, or a longer pool.

## Ratings rationale

- **Fun 3 (low confidence, inferred).** The crossing works mechanically: grow, stand,
  thaw behind you, really fall. Whether it is tense cannot be seen in stills, and the
  timing arithmetic above suggests it is too forgiving on this short pool. Needs a human.
- **Fluidity 3 (inferred from frame sequences).** Growth and thaw progress smoothly
  frame to frame. But the splash's motion is a flickering needle and then a comb, which
  reads as noise rather than water. Actual motion quality, and any perceived jitter of
  the 1 px swell, needs a live look.
- **Aesthetics 3.** The pixel discipline is exactly what design 03 §6.6 asks for, and
  the ice and grey plate read well. It is pulled down by the strip (green, flat, mirrors
  only underbrush, inset with cut ends), the edge seam, the needle and comb, and the
  speckle on grey.
