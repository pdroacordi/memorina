---
id: bugs/a-hazard-respawn-puts-ivo-back-into-the-gust-that-dropped-him
type: bug
title: A hazard respawn in the same open-sky room does not restart the regional gust clock, so Ivo reappears inside the gust that cut his jump short
status: resolved
severity: medium
tags: [air, weather, gust, hazard, respawn, mem-05]
related: [architecture/regional-weather-push, systems/air, systems/life-benches-death, playtests/2026-11-11-mem05-regional-weather]
created: 2026-11-11
updated: 2026-11-11
source_files:
  - scenes/world/environment/weather/region_wind.gd
  - scenes/world/game.gd
---

## Summary

`RegionWind` restarts its gust clock at calm only from `Game.room_changed`, and a hazard respawn that stays in
the same room emits no `room_changed`. If a gust carries Ivo short into a hazard (lake_shore's pool, design 03
§5.5's own example), he reappears behind the fade with the same gust still blowing.

## Symptom

Found in review of the uncommitted MEM-05 change, by reading the code. It has not been played.

The hazard beat takes about 1.25 s real (`hazard_sink_hold` 0.25 + `Fade.DURATION` 0.5 to black + 0.5 to clear).
A blizzard gust's rise, hold and fall last 5 profile s (`blizzard_gusts.tres`), which is 5 s at memory 1 and
about 16.7 s at the winter regions' 0.3. In most cases the gust is still blowing when he can move again. The
plan names "a gust can cut a jump short ... over a lake" as an expected outcome
(architecture/regional-weather-push, Consequences), so the first retry starts in the gust that ended the
previous one. Design 03 §5.5 ("Cansaço de nevasca": "uma transição de sala nunca o jogue numa rajada no meio de
um salto") covers a fade transition like this one.

## Root cause

- `region_wind.gd:47-48` restarts only when `room.has_sky() and (new_region or not _had_sky)`, inside
  `on_room_changed`.
- `game.gd` `_on_player_fell_into_hazard` (about lines 217-238) emits `room_changed` only when the respawn
  ground is in another room (`if room != null and room != _current_room`). Otherwise the clock runs on through
  the sink and both fades, because `RegionWind` is PAUSABLE and the world is not paused.
- The plan's restart list ("a walk-in, a door out, a bench or death build, a region cut") leaves out a hazard
  respawn.

## Play evidence (playtest 2026-11-11)

Reproduced in play: `playtests/2026-11-11-mem05-regional-weather`. Severity was raised from low to medium because
at memory 1 the respawn is not merely inside the gust: the gust pushes him back into the pool and costs lives with
no input.

- Timeline `tools/playtest/scripts/mem05_lake_pool_respawn_restored.json`: `"restored_guardians": [0]`, so frozen_lake
  sits at memory 1. Ivo spawns at (-150, -1650) on lake_shore and receives no input.
- Run it with `mem05_weather_probe_driver.gd` to see the gust clock.
- t ~8.6: the first gust (strength 1.0, 220 px/s, standing slide 52 px/s) slides him 74 px into the pool.
- t 9.69: he respawns at x -215, 9 px east of the pool's lip (x -224), with gust strength 0.96 and the clock
  running on (`gt` 9.69). He is sliding at once (vel.x -48) and falls in again at ~t 10.2.
- t 11.45: he respawns at x -207.8 as the gust ends. HP went 3 → 1.
- At the default 0.3 (`mem05_lake_pool_respawn.json`, a walk into the pool at t 26), the respawn lands at full
  gust strength with `gt` running through. 66 px/s cannot move a standing Ivo, so no second fall.
- A restart at calm fixes the loop. It does not stop the next gust, about 6 s later at memory 1, from pushing an
  idle Ivo in from the same spot. A respawn point further from the downwind lip, or a `WeatherShelter`, would.

## Fix

Fixed 2026-11-11 (MEM-05): `Game._on_player_fell_into_hazard` emits `hazard_respawned` after `respawn()` and the snap, behind the black; `game.tscn` connects it to `RegionWind.on_hazard_respawned`, which restarts the gust clock at calm (`region_wind_test.test_a_hazard_respawn_restarts_in_a_calm`). The next gust can still push an idle Ivo in from the same spot (MEM-16).

Original suggestion: a public `RegionWind.restart_calm()` that `Game` calls after `_player.respawn()`, behind
the black. It needs a new connection from `Game`, or a `Player.respawned` signal wired in `game.tscn`. Calling
it from `Player` would couple Ivo to the weather.

## Prevention

A `region_wind_test` case that gusts, simulates a same-room respawn and expects `drive() == 0`. Also add
"hazard respawn" to the restart list in `systems/air` (Regional weather), so later restart rules are checked
against it.
