---
id: architecture/regional-weather-push
type: architecture
title: BUILT (2026-11-11; MEM-05) - regional weather pushes through one region-scoped AirflowSource with a restartable gust clock that the snow reads too
status: active
tags: [air, wind, weather, region, gust, shelter, settings, accessibility, reachability, mem-05]
related: [systems/air, architecture/one-air-channel, features/regional-weather, systems/seasonal-art, systems/settings, systems/rooms, systems/guardians, architecture/memory-runs-through-pause, bugs/the-winter-squall-never-breaks-a-song-at-the-trials-memory, bugs/a-neighbour-room-in-another-region-runs-on-the-current-regions-memory, architecture/room-reachability-audit, architecture/wind-piles-a-bounded-crest]
created: 2026-11-11
updated: 2026-11-11
source_files:
  - scenes/world/environment/wind/airflow.gd
  - scenes/world/environment/wind/wind_zone.gd
  - resources/world/wind/wind_profile.gd
  - scenes/world/environment/region_weather/region_weather.gd
  - scenes/world/rooms/region.gd
  - scenes/world/rooms/room.gd
  - scenes/world/rooms/maps/jump_reach.gd
  - tools/maps/gen_world_shells.py
  - globals/settings/game_settings.gd
---

# Regional weather pushes the player (MEM-05)

## Context

Design 03 §5: weather pushes Ivo through the same channel as currents and songs (§5.3), scales with memory
(§5.1-5.2), gusts with calms that are the window to play (§5.4.1), is half-sheltered by a drawn Memorina (§5.4.2,
exists: `Player.memorina_shelter`), fully by every bench (exists: `bench.tscn` `Shelter`, a 96 px `DiscShelter`) and
by authored lees and cave mouths (§5.4.4). It is calm by default, no severe event starts right after entering
(§5.5), it drops drastically in guardian fights (§5.5), it never emits a colour pulse (§5.3), and an intensity
control exists from the start (§5.5). User, 2026-11-11: "Winter only (Recommended)" (built as data for MEM-06),
"Fixed per region (Recommended)" (one prevailing direction per region), "Yes, a slider (Recommended)" (a 0-100%
Weather intensity in Settings scaling the on-screen snow and the push).

Facts that shape it: `Airflow.sample` already multiplies every source by memory at the point; `WindProfile` already
models calm/rise/gust/fall; `RegionWeather` is ALWAYS and hidden only in interiors; the trials are their own
regions; no winter room holds a current, a cocoon or a seesaw. Open-sky winter rooms (surface, not `ROCK_SETS`):
threshold_fields, threshold_bridge, threshold_wayshrine, frost_shore, lighthouse_base, lake_fishing_village,
lake_shore. The Frost arena, the glacier, the ice caves, lake_well and the final arena are under rock.

## Options considered

1. **Where the push lives.** (a) One `WindZone` per open room, sized to the room: rejected; dozens of authored
   boxes, each with its own clock, so the snow cannot read one gust and an entry cannot restart them.
   (b) A source per `Region` in the region scene (the `RegionMemory` precedent): rejected; the clock must restart on
   `Game.room_changed`, which a region does not hear, and off-screen regions would tick for nothing.
   (c) **One `RegionWind` (an `AirflowSource`) under `World`, wired to `Game.room_changed` like `RegionMusic`**,
   holding the current region's profile and one clock: chosen.
2. **What the clock runs at.** (a) Real time: rejected; grey weather must stop (§5.1). (b) The region baseline:
   rejected; a pulse in a grey region would wake the blizzard's magnitude (Airflow scales by the local sample)
   but leave the cycle stuck in its calm, against §5.4 "tocar acorda a própria nevasca". (c) **Memory sampled at
   Ivo**, as a `WindZone` samples at its box: chosen. The magnitude stays local through `Airflow`, so a pulse wakes
   weather only around him (§5.2).
3. **Reachability.** (a) Model the push in `ReachLattice`: rejected; the lattice is time-free, and a worst-case
   headwind would mark half of winter unreachable while a calm is already still air. (b) Cap the peak below what
   breaks any jump: rejected; a drawn Memorina breaks only above 180 px/s at memory 1
   (`220 * 0.5 - wind_deadzone 90`, grip 0.4), which cancels Ivo's 192 px/s air speed, so §5.4.2 and "never
   breaks a jump" cannot both hold. (c) **Calm air is still air, held by a test; a gust is a timing obstacle**
   like a profiled current (the audit already lists "timing" as not modelled): chosen.
4. **Authored lees.** (a) An `AirflowShelter`: rejected; it zeroes all air, so a lee would also still a current
   or the Vendaval gale played into it. (b) **A `WeatherShelter` that only `RegionWind` consults**: chosen. Benches
   stay full `AirflowShelter`s (everything stops there, as now).
5. **Caves.** (a) Derive "covered" from row 0 of the map: rejected; threshold_ravine_cave's tunnel opens row 0 (a
   secret counts as open). (b) **A `Room.covered` export written by the generator** from its own ceiling rule
   (`not surface or id in ROCK_SETS or id in ROOM_SETS`): chosen; Room triggers are the generated part.

## Decision

**Data.** `WeatherProfile` (`resources/world/weather/weather_profile.gd`): `speed` (px/s at full gust and memory 1),
`gusts: WindProfile`, `fight_scale` (0..1), `fight_ease` (s), `gust_particles: PackedScene` (null: none).
`winter_blizzard.tres` + `blizzard_gusts.tres`. `Region` gains `weather: WeatherProfile` (null: no push) and
`@export_enum("West:-1", "East:1") var weather_wind: int`. `threshold`, `frost_edge` and `frozen_lake` get the
blizzard; home_village stays spring with none (design 03 §5.2's "Vila em 0.8 - neve leve" is not built: flagged).
MEM-06 is a new `.tres` on a Region; lightning (§5.5) would still be new code.

**Pure.** `WeatherGust` (RefCounted, `scenes/world/environment/weather/`): `restart()` (t = 0, the calm's start),
`step(delta, memory, fighting)` (t += delta * memory; the fight level eases toward `fight_scale` or 1 over
`fight_ease`; a fight ending restarts), `strength()` (`gusts.strength(t) * fight level`, 0..1),
`air(direction, intensity) -> float` (px/s before memory). It names no autoload.

**Node.** `RegionWind extends AirflowSource` (`region_wind.tscn`, `World/RegionWind`, PAUSABLE,
`process_physics_priority = -2` so it steps before `AirflowBody` at -1; export `subject: Player`):
- `on_room_changed(room)` (connected from `Game.room_changed`): takes `room.get_region()`'s profile and direction,
  caches the region's open-sky room rects, and calls `restart()` when the new room has sky and the last one did not,
  or was in another region (a walk-in, a door out, a bench or death build, a region cut).
- `_physics_process`: `step(delta, MemoryField.sample(subject feet), Guardian.fight_at(tree, subject position))`.
- `wind_at(point)`: zero unless the point lies in a cached open-sky rect and no visible `WeatherShelter` covers it;
  else `Vector2(direction * air(direction, Settings.weather_intensity()), 0)`. Horizontal only, so `lift_update`
  never changes a jump's height. Points in other regions get nothing (sidesteps the neighbour-region bug).
- `drive() -> float`: signed `strength * fight * intensity`, for the snow. No signals: both outputs are continuous
  and pulled. No `MemorySource`, no `ColorPulse`: weather never pulses (§5.3).

**Rooms.** `Room.covered` (generator-written) and `Room.has_sky() -> bool` (`not interior and not covered`).
`WeatherShelter` (legend `l`, root exports `width_cells` 3, `height_cells` 3, standing on its cell, draws nothing,
registers with `RegionWind` as `AirflowShelter` does with `Airflow`). `room_files_test`: an `l` lies in an open-sky
room of a region with weather, with solid ground in the column just upwind of its box over its lower two rows.

**Snow.** `RegionWeather` gets export `wind: RegionWind`; hides on `not room.has_sky()` (fading over 0.5 s on its
delta); multiplies `modulate.a` of every ambient layer by `Settings.weather_intensity()` (hidden at 0; `amount` is
never written); mounts the region's `gust_particles` (`winter_gust_particles.tscn`: whole-frame box, life ~1.2 s,
`initial_velocity` = `speed`, alpha ramp, `seasonal_particles.gdshader` with `ambient`) and each frame sets its
`direction.x = sign(drive)`, `speed_scale` = memory at the camera, `modulate.a = abs(drive)`. Snow driving sideways
is the gust; its absence is the calm.

**Settings.** `GameSettings.weather` (0..10 steps, default 10, `[general] weather`), `Settings.weather_intensity()`
(0..1), `Settings.set_weather(step)`; a StepBar row on General after Window size showing `SETTINGS_PERCENT`. It scales
regional weather only, never a `WindZone`, the gale or a guardian's gust. No puzzle may depend on regional wind.

**Numbers (first guess, profile seconds at memory 1).** `speed` 220 (the `WindZone` default): drawn peak 110 >
90, drift 8 px/s, breaks the song; standing undrawn slides 52 px/s; an upwind jump at peak is carried back 28 px/s.
`calm_time` 6.0, `rise_time` 1.5, `gust_time` 2.0, `fall_time` 1.5, `calm_strength` 0.0 (11 s period): a drawn song
survives 8.2 s of 11, an undrawn stand 7.3 s, still air 6 s; Ivo's running jump is ~1.3 s and a six-note song
~3 s. `fight_scale` 0.1 (22 px/s peak, under the deadzone, so a roll is untouched), `fight_ease` 1.0. Gusts break a
drawn song only where memory is above ~0.84: in a restored region or a pulse. At today's 0.3 (threshold, lake)
the peak is 66 px/s and a gust lasts 6.7 real s after a 20 s calm: no song breaks, an upwind jump loses ~86 px.

## Tests

- `tests/scenes/world/environment/weather/weather_gust_test.gd`: restart is calm; memory 0 stops the clock; the
  fight level eases to `fight_scale` and back and its end restarts; intensity 0 is still air; the sign follows.
- `winter_weather_bounds_test.gd` (the bound, real `.tres` and `Player` defaults, as `winter_trial_test` reads
  them): calm air <= 3 px/s and a `JumpReach` with that headwind keeps `gap()` and `reach_at(32 * k)`, k 0..4,
  within 4 px of still air; `calm_time >= 3.0 + airtime` (airtime from `JumpReach.arc`); at memory 1 the peak's
  `ground_drift(speed * memorina_shelter) >= STILL_SPEED_EPSILON`; `speed * fight_scale < wind_deadzone`.
- `region_wind_test.gd`: zero indoors, under rock, in another region, inside a `WeatherShelter`; restart on
  leaving a covered room; `region_wind.tscn` holds no `MemorySource`.
- `region_weather_test.gd`: hidden under rock; gust alpha 0 at intensity 0; `amount` unchanged.
- Settings: `game_settings_test` (clamp, default, round trip), `settings_screen_test` (the row steps),
  `settings_text_fit_test` (`SETTINGS_WEATHER`, `SETTINGS_PERCENT`), `settings_test` (MEMORY sessions keep 10).

## Consequences

- One clock per current region: the snow, the push and later SFX read the same gust.
- A gust can cut a jump short or carry it long over the ravine or a lake; the rise is the tell. Playtest it.
- The wind reaches every `AirflowBody` in open rooms (the crab, the boar, the bat) and piles lake_shore's pool
  (`WindCrest`); Congelar in a gust may pin a ~20 px ramp. Playtest; unchanged physics.
- Snow stops in caves in every region, not only winter (the `has_sky` hide).
- Adds `RegionWind` (PAUSABLE) and the gust layer (ALWAYS, under `RegionWeather`) to the pause-mode map.
