---
id: architecture/wind-piles-a-bounded-crest
type: architecture
title: Wind piles a bounded crest against the downwind bank, and Congelar pins it into a ramp (PLAN for PZL-03)
status: active
tags: [water, wind, crest, gale, freeze, ramp, slope, plan, pzl-03]
related: [architecture/ice-is-its-own-sheet, architecture/memory-gated-height-field, architecture/one-air-channel, architecture/water-two-projections, systems/air, systems/water, bugs/water-swell-flattened-by-spread]
created: 2026-10-07
updated: 2026-10-07
source_files:
  - scenes/world/environment/water/water_body.gd
  - scenes/world/environment/water/water_surface_field.gd
  - resources/world/water/water_profile.gd
  - scenes/world/memory/song_effects/gale/gale_field.gd
---

## Summary

PLAN, not built (2026-10-07). Combinado 2, "A Onda Parada" (design 02 §8.4): Vendaval from the
shore raises a crest, Congelar before it settles fixes it as a ramp to the top of a wall; Congelar
too early freezes a low wave. The spring field cannot raise such a crest, so a bounded `WindCrest`
(one signed height per body, built by the along-body wind at the body's memory) is added to the
springs' target like the swell. Freezing uses `ice-is-its-own-sheet` unchanged: the pin keeps the
crest, the band captures it, the segment chain is the slope.

## Context

- `WaterBody._blow` adds `-wind * wind_stress * delta * (column - half) / half` as displacement.
  Steady state is about `damping / stiffness * D` = 2/25 x (0.05 x 260) = about 1 px at the gale's
  260 px/s, two orders short of a ramp. Settling is under 1 s (omega 5 rad/s, damping 0.2).
- The sign piles water UPWIND (the downwind half is pushed down) while the comment and
  `systems/air` say downwind; no test covers it. For `godot-reviewer` to record as a bug.
- Heights above 12 px are clipped (`WaterBody.HEADROOM`).
- A lake (`w`) has no `WaterProfile` and is never held out (user, 2026-09-30): the lake is a pool
  (`f`).

## Options considered

- **Retune `wind_stress` about 150x.** Stiffness 25/s² returns a 160 px crest in about 0.6 s after
  the gale (no window); splashes, foam, veil and headroom all assume a few px. Rejected.
- **Paint the crest envelope in `[water]`.** Readable, but the only above-water cells are PZL-09's
  reach (`r`, "rain brings it here"): Chuva + Congelar would then solve the puzzle without the gale.
  A second envelope character for one puzzle is a second concept. Rejected.
- **Chosen: `WindCrest`**, a bounded crest model whose shape is a target offset. The springs keep
  splashes and rings on top; the field couples on the offset from its target, so the wedge is not
  smoothed away (`bugs/water-swell-flattened-by-spread`).

## Decision

- **`WindCrest`** (new, pure `RefCounted`, `environment/water/wind_crest.gd`):
  `_init(profile, width_px)`; `step(delta, wind, rate)` with `wind` the mean of the body's sampled
  winds (signed px/s, already memory-scaled by `Airflow`) and `rate` the mean column rate;
  `height()` (signed px, + piles at the right end); `offset(column, count, column_width)`, a linear
  wedge `height * max(0, 1 - d / crest_length)` from the downwind end. Cap =
  `min(crest_height, crest_per_fetch * width)`. Drive = `sign(w) * clamp((|w| - crest_min_wind) /
  (crest_full_wind - crest_min_wind), 0, 1)`. Grows toward `drive * cap` at `cap / crest_rise_time
  * rate` px/s, settles (or passes through 0 to the other bank) at `cap / crest_settle_time * rate`.
  At rate 0 it is unchanged bit for bit (03 §6.2: the crest stays).
- **`WaterProfile`**: `wind_stress` and `WaterBody._blow` go (one way wind moves water). New group
  Crest, starting numbers: `crest_height` 160 px, `crest_per_fetch` 0.5, `crest_length` 256 px,
  `crest_rise_time` 12 s, `crest_settle_time` 4 s, `crest_min_wind` 40 px/s, `crest_full_wind`
  150 px/s. `crest_height` 0 turns it off.
- **`WaterBody`**: owns a `WindCrest` when the profile has one; steps it above the visibility gate
  (a puzzle state, a scalar); fills an offsets array passed to `_field.step`; quads and notifier
  take `max(HEADROOM, cap + 4)` of headroom.
- Freezing: nothing new. The pin keeps the crest; the band's bottom is the rest line plus thickness,
  so the frozen wave is solid ice down to the water; the chain gives the slope; the thaw from the
  origin (the shore) melts the ramp's foot first. A thawed crest column is unpinned and falls as a
  wave.
- **Slopes are new to the game.** `Character` sets `floor_snap_length` (start 8 px) so Ivo does not
  hop walking down the ramp; `floor_max_angle` stays 45°, which `IceCollider`'s one-way rule
  mirrors.

## Consequences

- Rules kept: wind stays a velocity the air carries (the crest reads it, never pushes a body);
  nothing moves at memory 0; lakes are untouched; the thaw ignores memory.
- SOLID: the crest is one class with one job, its tuning is profile data (open/closed: a still
  pond is a profile with `crest_height` 0).
- Suite `wind_crest_test.gd`: no wind, nothing; full wind reaches the cap in `crest_rise_time` at
  memory 1, at half speed at 0.5; holds bit for bit at 0; settles in `crest_settle_time`; under
  `crest_min_wind` nothing; right end for +wind, left for -wind; cap limited by fetch; the offset is
  a wedge reaching 0 at `crest_length`; a sign flip passes through 0. `water_surface_field_test`:
  offsets are followed exactly in steady state.
- Trial: `water_trial` section 2 in `trials_solstice` (see `a-pool-rests-below-its-painted-reach`
  for the room). Stone shore 4 cells, an `f` pool 12 cells by 3 deep, no reach painted, a stone wall
  at its right end 7 cells (224 px) above the shore with its top walkable. Ivo plays Vendaval at
  the shore's edge facing right, then Congelar.
- Numbers: needed crest about 224 - 143 + 8 (inset) + 8 (margin) = 97 px (61% of cap); full crest
  leaves 72 px to the top. Fastest Congelar after Vendaval: six notes (5 x 0.25 s) plus the last
  ring (about 1.6 s), the pulse reaching the pool, the front crossing 384 px at 160 px/s: about 5.4 s,
  giving 45% (72 px): the low wave fails. Window about 8 s to 13 s after Vendaval's pulse (sustain
  ends at 12 s; contraction halves the gale, target about 0.45 cap). Ramp slope atan(160/256) = 32°.
- `water_trial_test.gd`: the wall top is beyond a jump from the shore and from ice at rest; a full
  crest (real profile, real width) leaves it within `peak - MARGIN`; the crest at the fastest
  Congelar does not; every ramp segment is walkable; `GaleShape` over the pool's columns from the
  shore gives a mean wind at or above `crest_full_wind`. Playtests `song_gale_freeze_crest.json`
  and an early-Congelar timeline that fails.
- Risks: slope locomotion (snap, the animation resolver on a downslope, `JumpReach` assumes flat
  ground, so the test jumps from the ramp's top as flat). The reflection axis rides the local
  surface, so a 160 px crest mirrors the world 160 px up; check it, clamp the axis rise if it reads
  wrong. Any natural `W` current over a pool now builds a crest (none overlaps a pool today; the
  winter squall ends at the far pool's edge, so measure it). Volume is not conserved (no drawdown
  upwind): accepted. When built, update `systems/air` ("Wind moves water") and `systems/water`.
