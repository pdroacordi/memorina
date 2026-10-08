---
id: architecture/the-shell-displaces-water-into-the-reach
type: architecture
title: Redoma's held-out volume raises the pool into its painted reach, and Congelar freezes the raised water and its curved edge (PZL-06)
status: active
tags: [water, redoma, bell-jar, displacement, freeze, ice, held-discs, plan, pzl-06]
related: [architecture/ice-is-its-own-sheet, architecture/a-pool-rests-below-its-painted-reach, architecture/the-bell-jar-closes-once, architecture/water-two-projections, systems/bell-jar, systems/water, gotchas/glsl-gdscript-math-must-be-duplicated, bugs/water-that-returns-leaves-its-dry-floor-as-safe-ground]
created: 2026-10-07
updated: 2026-10-07
source_files:
  - scenes/world/environment/water/water_body.gd
  - scenes/world/environment/water/water_common.gdshaderinc
  - scenes/world/memory/song_effects/shell/frost_shell.gd
  - scenes/world/interactables/freezable_water/freezable_water.gd
---

## Summary

Built 2026-10-08 (PZL-06) with the user's answers to the questions at the end ("Chão elevado", "Só a Redoma", "Não precisa"): the cap is a shell reach of its own (`u`, not `r`), there is no dam (the floor, not the arc, is the way up), and `BasinVolume` became `HeldDiscs.displaced_rise` (held area below the rest line over the wet width). The real rise is lower than the estimate below (about 71 px, not 110-130, which counted disc area above the rest line), so the trial's reach is 2 rows and its exit 5 cells up. Inverno
Logico 2 (design 02 §8, §7.4). The user chose "Água sobe em volta" on 2026-10-07: the water the
shell displaces rises around it, and the frozen wall stands above the normal level. Plan: the
volume held out of the shells' discs raises the whole body's level, solved for volume and clamped
to the painted reach (PZL-09's `r`); Congelar then freezes the raised water, whose edge follows
the shell's lower arc (the curved wall). Built on `ice-is-its-own-sheet`.

## Context

- `WaterBody.hold_out()` dries the columns whose waterline is inside a disc; the water stands
  against the curve pixel for pixel (`wc_held()` = `_refresh_dry()`), nothing is displaced.
- Lakes are never held out (user, 2026-09-30): the design's "lago" is a pool, `f` plus `r`.
- The pulse is born at Ivo's feet (`Player.song_played` sends `global_position`; his capsule is
  centred 27 px above it). Redoma: 192 px, 8 s sustain, 5 s contraction.
- A concave arc is walkable only to 45°, 0.29 r = 56 px above its bottom for r 192, so the arc alone
  cannot be a ramp to anything high. Above the disc's centre the water lies over the dome as well
  as under the bowl: two bands per column, which the sheet does not hold.

## Options considered

- **Global rise** (chosen): the held volume raises the whole level; the ice stands at the raised
  level with its edge on the arc.
- **Local bulge against the shell**, a crest-like offset (PZL-03's machinery): the frozen ramp
  rises toward the shell and ends in a cliff at the arc, and Ivo, inside the shell on the bank,
  cannot reach the ramp's foot on the far side. Rejected for now.
- **A free-standing arch** (ice along the whole wetted arc, dome included): two bands per column.
  Rejected (see `ice-is-its-own-sheet`).
- Wall after the shell: let the flood submerge the ice (wrong read), or **the ice holds the disc it
  froze against until that ice thaws** (chosen, a dam).

## Decision

- **`HeldDiscs`** (new, pure static, `environment/water/held_discs.gd`): `contains(point, discs)`,
  the one GDScript copy of `wc_held()` (`distance < r`; `_refresh_dry` and `_wet_outlines` call
  it; the shader's comment points here); `chord(x, discs) -> Vector2`, the merged covered y-span
  at x; `topmost_water(x, line_y, floor_y, discs) -> float`, the line if outside, else the span's
  lower end if above the floor, else INF.
- **`BasinVolume`** (new, pure static, `basin_volume.gd`): `volume(level_y, left, column_width,
  floors, discs)` sampled every `RATE_STRIDE` columns; `level_for(volume, top_y, ...)` by bisection
  to 0.5 px, clamped to the painted top (overflow spills).
- **`WaterBody`**: `set_level(y)` records the commanded level; the drawn level is commanded minus
  `_displaced`, which eases toward `commanded - level_for(volume(commanded, no discs), discs)` at
  `WaterProfile.displace_speed` (start 60 px/s) times the mean column rate; the target is recomputed
  when the discs or the command change, at most every `RATE_REFRESH_FRAMES`, above the visibility
  gate. `set_lid(true)` (from `FreezableWater` while frozen): `_displaced` may only shrink, so
  Congelar then Redoma raises nothing. With no reach painted (top = rest), it clamps to 0: the
  winter well does not change. `ice_top(c)` uses `HeldDiscs.topmost_water` for held columns.
  `held_discs()` returns the discs.
- **`FreezableWater`**: a held column captures its band at the arc (bottom = top + thickness). At
  the first such capture it copies the discs covering captured columns and holds them itself
  (`hold_out(self, ...)`; one shell plus its dam fit `MAX_HELD` 4), so the water keeps standing
  against the ice's arc, still displaced, after the shell lets go. It releases when no captured
  column under the copy remains: the pocket floods and the level falls back.
- Signals: none new. `FrostShell` is unchanged.

## Consequences

- Rules kept: the GLSL disc test is untouched and its GDScript side becomes one function; lakes
  stay never held out; growth needs living water; the thaw ignores memory.
- SOLID: volume math and disc math are pure and reused (single responsibility); a new holder (the
  dam) is another `hold_out` caller, not a branch in `WaterBody` (open/closed).
- Suites: `held_discs_test.gd` (matches the old per-column test on a grid; two overlapping discs
  merge; topmost under a disc is its lower arc; dry to the floor is INF). `basin_volume_test.gd`
  (no disc, identity; a submerged disc raises by area / width; clamped at the top; a disc above the
  water raises nothing; volume is conserved to 1 px x width). `water_hold_out_test`: the level
  rises into a painted reach, not past it; a lid refuses the rise. A scene test: the dam keeps the
  pocket dry after the shell releases until its ice thaws.
- Trial: `water_trial` section 3 (room in `a-pool-rests-below-its-painted-reach`). Stone bank; an
  `f` pool 16 cells wide and 7 deep (the disc from the bank floor reaches F + 192, the floor is at
  F + 216); `r` 3 rows (96 px) above; an exit in the far stone wall 6 cells above the bank.
- Numbers: held area about a quarter disc plus a strip, 35-42k px², over about 320 px of wet width:
  110-130 px, clamped at 96. The sheet stands at F - 88; the arc crosses it about 171 px from Ivo,
  155 px from the bank's edge (a running jump 88 px up). Exit: 104 px above the sheet (within
  143 - 8), 192 above the bank and 200 above ice at the normal level (beyond 143). Rise at memory 1
  takes about 1.6 s.
- `water_trial_test.gd`: the exit is out of reach from the bank and from ice at rest, and within
  reach from the raised sheet; the jump onto the sheet fits `JumpReach`; `BasinVolume` with the
  real pool and the real disc reaches the reach. Playtest `song_bell_jar_freeze_wall.json` and the
  inverse order.
- Risks: water may stand a few px above the bank's top while a shell without ice shrinks faster
  than the level eases down; playtest it. Before Congelar, Ivo dropping into the pocket passes
  through the shell (he is excepted) into the water below the arc: the existing rule. The ice band
  is per 2 px column while the water's arc is per pixel: a 1 px seam is possible at steep parts.
- When built, update `systems/bell-jar` (displacement, the dam, the user's decision quoted with its
  date) and `systems/water`.

## Needs the user's decision

1. **The ramp.** In this reading the arc is the wall bounding a dry pocket and the walkable gain is
   the raised frozen sheet; the arc itself is not a ramp to the exit (the 45° limit above). Confirm,
   or choose the local bulge or a two-band arch.
2. **Chuva also solves it.** The reach that bounds the rise is also where rain brings the water,
   so Chuva then Congelar gives the same sheet. Accept as composition (§7.4) or keep displacement
   out of rain's reach (a second reach character).
3. **The arc's life.** With today's thaw (1.5 s, then 48 px/s from the origin on the bank) the arc
   melts within about 2-5 s, long before the shell (up to 13 s) vanishes; the far sheet outlasts it.
   If "fica quando a casca some" must hold for the arc, either a live shell holding the body pauses
   its ice's thaw clock (one rule in `IceFront`) or this pool kind gets its own `IceProfile` (a new
   preset and character). Not needed for the solution above.

## Revision (2026-10-08, as built)

The Decision and Consequences above are the plan. What was built: `HeldDiscs` (pure: `contains`,
`held_area`, `displaced_rise`; no `BasinVolume`, no `chord`/`topmost_water`); `WaterBody.displaces`,
`displace_speed` (on the body, not the profile), `set_lid`, the target recomputed only when the
discs change (`_held_changed`); a shell reach of its own (`u`) instead of `r`; no dam. Suites:
`held_discs_test`, `water_displacement_test`, the parser and basins tests, `water_trial_test`
section 3. The wind crest's bank cap is measured from the line as it stands each step, so a raised
pool still piles no water over its banks.
