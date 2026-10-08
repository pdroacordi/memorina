---
id: bugs/the-winter-squall-never-breaks-a-song-at-the-trials-memory
type: bug
title: The winter trial's squall peaks at 73.5 px/s on a drawn Memorina at the trials' memory 0.35, under the 90 px/s deadzone, so Soltar plays inside it without Redoma
status: fixed
severity: high
tags: [air, wind, wind-zone, bell-jar, redoma, release, soltar, trials, memory, pzl-07]
related: [systems/air, systems/bell-jar, architecture/one-air-channel, playtests/2026-10-07-redoma-then-soltar-in-the-squall]
created: 2026-10-07
updated: 2026-10-07
source_files:
  - scenes/world/rooms/trials_winter/contents/winter_trial.room
  - resources/world/wind/squall_wind.tres
  - tests/scenes/world/rooms/trials/winter_trial_test.gd
  - scenes/world/environment/wind/airflow.gd
  - scenes/world/environment/wind/wind_zone.gd
---

## Summary

PZL-07 (design 02 section 8, Inverno Logico 1) relies on the squall at `winter_trial.room:73`
breaking any song played in it. Every wind is scaled by memory at the sampled point, and the
trials region's baseline is 0.35. A full gust on a drawn Memorina is
420 x 1.0 x 0.35 x 0.5 = 73.5 px/s, under `LocomotionStats.wind_deadzone` (90). Ivo stays
still and Soltar plays anywhere in the squall, so Redoma is never needed.

## Symptom

Found in review (arithmetic, not yet played). Stand in the squall (cols 41-51) during a lull,
draw the Memorina and play Soltar within 288 px of the hinge (col 51). Nothing interrupts the
song and the drawbridge falls. Redoma, the puzzle's subject, is optional.

## Root cause

- `Airflow.sample` returns `wind * _memory.sample(point)` (airflow.gd:51). Outside any pulse
  that is the region baseline: `trials_winter.tscn` `Memory.authored = 0.35`.
- `WindZone` also runs its profile clock at that memory (`_time += delta * rate`,
  wind_zone.gd:55-57). Every phase of the squall lasts 1 / 0.35 = 2.9x longer in real seconds.
- `winter_trial_test._longest_calm` (winter_trial_test.gd:114) and
  `test_no_calm_is_long_enough_for_a_song` (line 141) use `zone.speed * strength * shelter`
  with no memory factor and profile seconds as real seconds. At memory 1 the reasoning holds:
  the longest calm is about 0.88 s against 1.25 s for five note gaps. In the game the gust
  never reaches the deadzone.

The wrong-order case happens outside any pulse, so it always sees the baseline. Other wind
puzzles (autumn) were sized at memory 1 safely only because their positive case is inside a
song's pulse, where memory is near 1.

## Fix

Fixed before commit (2026-10-07) with the second option: `SquallMemory`, a RECT `MemorySource`
(strength 1) in `trials_winter.tscn` over the squall's box, so the spot is remembered and the wind
blows and gusts at full rate there. A faster wind tuned for 0.35 was rejected: inside Soltar's own
pulse (memory near 1) it would be too strong to walk against to the bridge. `winter_trial_test`
reads the region's memory and the source (`_squall_memory`) and applies it to the wind's strength
and its clock.

Original analysis: the test must read the region's baseline (`trials_winter.tscn` Memory `authored`)
and apply it twice: to the wind's magnitude and to the clock (real calm = profile calm / memory).
Then retune the squall so that `speed x 0.35 x memorina_shelter > wind_deadzone` with margin
(speed above about 515 px/s), and so that the time below the deadzone, in real seconds, stays
under five note gaps. Another option is a `MemorySource` that keeps the squall's spot
remembered, which makes the zone's memory explicit.

## Played (2026-10-07)

`playtests/2026-10-07-redoma-then-soltar-in-the-squall` reproduced the bug and verified the fix:

- Before `SquallMemory`, Control A drew in a lull at x 1447 and played Soltar with
  `vel (0, 0)` through a gust. The bridge fell with no Redoma
  (`screenshots/2026-10-07-redoma-then-soltar-in-the-squall/old_build_control_a_bridge_falls_without_redoma.png`).
  Undrawn in the grey gust he drifted at 22.8 px/s (147 px/s of air).
- After it (reimported), a draw at the start of a lull got two notes in at the fastest gap
  (0.27 s) before the gust broke the song (t ~3.95). Tries released into a gust could not draw.

## Prevention

A puzzle test that relies on wind outside a pulse must use the region's baseline memory for
both the wind's strength and its gust timing. A positive case inside a pulse may assume
memory near 1.
