---
id: bugs/splash-rings-the-alternating-column-mode
type: bug
title: A splash crest reads as a 2 px needle and then a comb of teeth, because the impulse is one column wide and rings the lattice's alternating-column mode
status: fixed
severity: medium
tags: [water, splash, springs, pixel-art, crest, memory]
related: [playtests/2026-09-23-generated-water, bugs/water-swell-flattened-by-spread, architecture/memory-gated-height-field]
created: 2026-09-23
updated: 2026-09-23
source_files:
  - scenes/world/environment/water/water_body.gd
  - scenes/world/environment/water/water_surface_field.gd
  - resources/world/water/water_profile.gd
---

## Summary

`WaterBody.splash` writes a dent exactly one column wide, with lower neighbours rising on
either side. That shape is almost entirely the surface's highest spatial frequency: every
other column goes up while its neighbours go down. The springs then ring that mode. On
screen the crest never reads as a mound: it is a single 2 px wide white needle, then a
comb of 1 px teeth that lingers for seconds in grey water. Design 03 §6.2 calls this crest
the image to show first.

## Symptom

`tools/playtest/scripts/water_splash_closeup.json` (Ivo jumps into Downtown's pit pool,
memory about 0.1), captured on 224d721 and again on 20597f0. See
`playtests/screenshots/2026-09-23-generated-water/04_splash_needle_then_comb.png`:

- t 3.30 (entry): a V notch 1 column wide.
- t 3.40 to 3.50: a 2 px wide needle about 5 px tall stands on the waterline.
- t 3.80 to 4.20: "M" shapes and then alternating 1 px teeth across about 12 columns.
- t 5.2 to 10.5: the comb has spread into 1 px zig-zag chop that is still visible 7 s
  after the splash.

A headless replica of `_substep` at the default `WaterProfile`, rate 0.1, depth 5 px,
matches the frames. 0.4 s after impact the heights around the centre are
`[-2, 5, -2]` (the needle). At 5 s they are `[-1, 1, -1, 1, -1]` (the comb). A
raised-cosine dent across 5 columns under the same springs gives a smooth dip that
travels outward as two mounds, and it never shows alternating columns.

## Root cause

- `water_body.gd:127-131`: `_field.disturb(centre, -depth)` plus neighbours at
  `+depth*0.5, +depth*0.33, +depth*0.17`. The step between adjacent columns is 1.5×depth,
  so most of the impulse's energy lands in the alternating-column mode.
- `water_surface_field.gd:115-119`: damping is the same at every frequency
  (`- damping * v`). That mode is the fastest one (ω ≈ √(stiffness + 4·spread) ≈ 90
  rad/s of water time), and nothing damps it harder than the slow swell, so it outlives
  the splash's useful shape. At memory 0.1 its half period is about 0.35 s of real time,
  which is the needle-to-dent flip seen between frames.
- At memory exactly 0 (not reproducible in this build, because no water sits in memory 0)
  the frozen "crest" would be this raw written shape: a 2 px wide notch with low shoulders.
  That is an inference from `disturb()` writing position, not an observation.

## Fix

Not fixed. Candidate fixes; the first is the real one:

1. Make the impulse smooth across several columns: a dent shaped as a raised cosine over
   `splash_half_width` columns, with the rising crest as a wider, lower raised cosine
   outside it. The difference between adjacent columns should stay well under 1 px per
   px of depth.
2. Add frequency-dependent damping (a viscosity term `viscosity * (v_l + v_r - 2v)` in
   `_substep`). It kills the checkerboard mode and leaves the swell and long ripples
   alone.
3. Tuning-only mitigation (weaker): `column_width` 2 → 3 widens the teeth, and `spread`
   2000 → 800 slows the ring. Both also change how ripples travel, so re-check the swell
   test.

## Prevention

A splash test should assert shape, not only energy. After the impulse, no three
consecutive columns should alternate sign around the rest line by at least 1 px (the
rounded heights the shader draws).

## Fix

Fixed in fae1438 (2026-09-23): `WaterBody.splash` writes a Ricker (Mexican-hat) profile over +/-3 splash widths instead of a one-column notch, and `WaterProfile.viscosity` (4.0) damps velocity against the neighbours. `test_the_zig_zag_mode_dies_quickly` guards the damping.
