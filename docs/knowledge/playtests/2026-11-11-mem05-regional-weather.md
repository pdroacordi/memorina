---
id: playtests/2026-11-11-mem05-regional-weather
type: playtest
title: MEM-05 regional winter weather - the gust cycle, push, song break, cave fade, calm restart and the intensity row all work as planned; a restored lake's gust re-drowns a respawned Ivo (two lives, no input)
status: active
build: 9afdfdbc + uncommitted MEM-05 working tree (no file in scenes/resources/globals/assets changed after this session's 13:24 import; checked 13:42)
area_tested: "threshold_bridge, threshold_fields + farmhouse door, threshold_ravine_cave, lake_shore + its pool, lake_ice_caves, woods_root_caves / woods_deep, Settings > General"
tags: [air, wind, weather, gust, region, shelter, settings, accessibility, hazard, respawn, mem-05]
related: [architecture/regional-weather-push, systems/air, systems/settings, systems/seasonal-art, bugs/a-hazard-respawn-puts-ivo-back-into-the-gust-that-dropped-him, playtests/2026-10-07-redoma-then-soltar-in-the-squall]
created: 2026-11-11
updated: 2026-11-11
ratings: { fun: 3, fluidity: 3, aesthetics: 3 }
screenshots:
  - screenshots/2026-11-11-mem05-regional-weather/grey_calm_vs_gust_streaks.png
  - screenshots/2026-11-11-mem05-regional-weather/streaks_move_west_0.1s_flipbook.png
  - screenshots/2026-11-11-mem05-regional-weather/headwind_gust_jump_falls_short.png
  - screenshots/2026-11-11-mem05-regional-weather/pulse_gust_breaks_freeze_3_notes_in.png
  - screenshots/2026-11-11-mem05-regional-weather/mem1_gust_idle_ivo_slides_back.png
  - screenshots/2026-11-11-mem05-regional-weather/grey_gust_brace_at_full_speed.png
  - screenshots/2026-11-11-mem05-regional-weather/ravine_cave_in_and_out.png
  - screenshots/2026-11-11-mem05-regional-weather/settings_weather_row_en_pt.png
  - screenshots/2026-11-11-mem05-regional-weather/streaks_over_solid_ground.png
  - screenshots/2026-11-11-mem05-regional-weather/restored_lake_respawn_loop_two_lives.png
---

## What was tested

Windowed runs of `tools/playtest/playtest_runner.tscn` through a new probe driver,
`tools/playtest/scripts/mem05_weather_probe_driver.gd`. It prints `[wx]` lines every 50-100 ms real: the
`WeatherGust` clock (`gt`, profile s), strength, fight level, `drive()`, `wind_at(feet)`, the summed `Airflow`
at the feet, the memory there, `Settings.weather_intensity()`, `RegionWeather` visibility, sky level, gust-layer
alpha/direction/speed scale and the ambient alpha. It also prints `[sig]` for Ivo's Memorina signals.
`WX_MEMORY=<v>` writes the field's baseline every frame. Runs that use it are labelled **forced**. Timelines are
`tools/playtest/scripts/mem05_*.json`. All `t` values are the runner's unpaused clock. A fresh `APPDATA` was used
per run, and every run printed its scratch user dir.

1. threshold_bridge west deck (6800, 160), 50 s standing, with hops in the calm and the gust.
2. A running jump over the bridge gap (west deck to east deck, into the west wind), in the calm (t 2) and at the
   gust's peak (t 27).
3. FREEZE (`known_songs [0]`) in the calm at default memory. Its pulse lifts Ivo's memory to 1, and FREEZE is
   played again as the quickened gust rises. Then FREEZE through a rising gust at default memory 0.3.
4. The east deck by the ravine lip at **forced** memory 1.
5. The ravine floor into `threshold_ravine_cave` through the secret wall during a gust, and back out by the
   tunnel's ledge. The fields' farmhouse door in and out during a gust.
6. Settings > General from the pause menu (en and pt_BR): the Weather intensity row at 100, 50 and 0 %, clamped
   at 0, then back to 100. At 0 %: hops through a full gust.
7. lake_shore through a cycle. The teleports into lake_ice_caves, woods_root_caves (spring, no weather) and
   woods_deep.
8. Walking into lake_shore's pool in a gust: at 0.3, at **forced** 1, and with `"restored_guardians": [0]`
   (natural memory 1 on frozen_lake).

## Findings

**The cycle matches the plan's numbers.** At threshold's 0.3 the calm lasts 20.0 s, the rise 5 s, the full gust
6.1 s (t 25.4-31.5) and the fall 5 s. The cycle is 36.7 s. The peak is `wind` 220 x memory 0.3 = `air` -66 px/s.
At memory 1 (in a pulse) the gust arrived 5 s after the pulse and peaked at -220.

**What the push does at today's memory (0.3): only the air.** 66 px/s is under `wind_deadzone` 90, so a standing
or walking Ivo is never moved, and a walk keeps 192 px/s both ways. In the air the full 66 px/s carries him:
- A hop in place drifts ~76 px west. Four hops in one gust walked him off the west deck and down three steps
  (6800 → 6508, y 160 → 288).
- The bridge gap: the calm running jump lands at x 7177, 41 px past the east lip (7136). The same inputs at the
  peak fly at 126 px/s and land at x 7126 on the fallen span, 10 px short. The span is one 96 px jump below the
  east deck, so a miss costs a hop, not a life
  (`headwind_gust_jump_falls_short.png`). From the calm margin, the eastward jump fails for strength above ~0.5:
  about t 22.5-34, ~11.5 s of every 36.7 s. That is inferred from the logged arc, not swept.

**The sideways snow reads as wind from the east, but only in motion.** The gust layer's alpha follows `drive`
(0 in the calm, 1 at the peak). A 0.1 s flipbook shows the dashes moving west ~7 game px per 0.1 s at 0.3, which
matches the 66 px/s push (`streaks_move_west_0.1s_flipbook.png`). In a still frame they are sparse 6x1 white
dashes with no tail, so the direction cannot be read from a screenshot (`grey_calm_vs_gust_streaks.png`). The calm
shows no dashes at all, so the calm does read as the window, by absence. Inferred, not observed: at 0.3 the dashes
drift slowly (`speed_scale` 0.3). That matches "grey is stopped time", but a player may read it as "floating
lines" more than a blizzard. Needs a human eye.

**Brace without resistance (feel, medium confidence).** Walking east into a 0.3 peak gust plays the `brace` clip
on every logged frame (carry 66 ≥ `brace_wind` 60) while he runs at the full 192 px/s
(`grey_gust_brace_at_full_speed.png`: a deep lean, arm over the face). The body says "fighting the wind" and the
motion says nothing. Before MEM-05 this only happened in trial squalls. Now it happens in every winter gust.
Suggest `brace_wind` ≥ `wind_deadzone`, or a ground slowdown below the deadzone.

**A gust breaks a song only where memory is high.** These are the plan's claims, confirmed:
- At 0.3, FREEZE played through a rising gust (strength 0.30 → 0.97, `air` up to -64) completed (`song_played`
  t 29.26).
- Inside its own earlier pulse (memory 1), FREEZE drawn at gust strength 0.10 broke on the 3rd note at strength
  ~0.85 (`sequence_failed` t 10.46, then sheathed; `pulse_gust_breaks_freeze_3_notes_in.png`).
- A draw pressed at the peak at memory 1 is refused silently, because Ivo is already sliding
  (`is_still()` false, no `memorina_drawn`).
- Whether the break *reads* as the wind's doing (the sheet's flash, a sound) cannot be judged from frames.

**A song wakes its own blizzard, hard.** Right after the 0.3 gust song, the pulse lifted Ivo's memory to 1 under a
full gust. With no input he slid at 52 px/s, was carried off a step at 220 px/s in the air, and drifted 140 px
west into threshold_fields within 1.7 s. This is design 03 §5.4's intent ("tocar acorda a própria nevasca"),
but the player has no beat between the song's end and the shove.

**Idle at memory 1: he skates backwards in the idle pose** (`mem1_gust_idle_ivo_slides_back.png`). Undrawn, he
slides 52 px/s with no lean and no stagger. **Forced** memory 1 on the east deck: standing 44 px from the lip, he
was slid into the ravine in one gust (7180 → floor 352) with no input.

**Covered rooms and the restart work as planned.**
- Ravine cave: through the secret wall the wind is 0 the moment his feet leave the bridge's rect, and the snow
  fades 1 → 0 over ~0.5 s (sky 0.62 at +0.2 s, 0.07 at +0.5 s).
- Out by the ledge jump mid-gust (strength 1.0 inside), the clock restarts at `gt` 0.01 on the room change, with
  no dashes, and the snow fades back in over 0.5 s (`ravine_cave_in_and_out.png`).
- The farmhouse door, in and out at peak: the same restart (`gt` 0.03 on arrival outside).
- lake_ice_caves (winter) and woods_root_caves (spring, no weather) both hide the falling layer. woods_deep shows
  it (alpha 0.53).
- Not exercised: a bench rebuild, a death rebuild, a region cut by walking.

**Weather intensity row.** The row sits on General after Window size, a 10-cell StepBar with `< 100% >`. It steps
in tens, clamps at 0, and goes back to 100. "Weather intensity" / "Intensidade do clima" fit with room to spare
(`settings_weather_row_en_pt.png`). At 100 % the value `< 100% >` sits ~5 game px from the last cell: tight, not
clipped. At 0 % `RegionWeather` is hidden (falling snow too), and four hops through a full gust
(strength 1.0) stayed at x 6800. Back at 100 % mid-gust, the dashes return at once at full alpha.

**Dashes draw over solid ground** (`streaks_over_solid_ground.png`, lake_shore). The gust layer, like the
existing falling layer, draws over the ground tiles. A falling dot inside rock was barely visible. A horizontal
white dash crossing the cobbles reads as a glitch. threshold's rock tiles also carry small east-pointing arrow
marks that look like streaks pointing the other way. That is tileset art, present in the calm too.

**BUG: a restored lake's gust re-drowns a respawned Ivo.** With `"restored_guardians": [0]` (frozen_lake at
memory 1), standing at (-150, -1632) with **no input** (`restored_lake_respawn_loop_two_lives.png`):
- The gust slid him 74 px into lake_shore's pool (falls at ~t 8.6).
- He respawned at x -215, 9 px from the pool's lip, at t 9.69, in the same gust (strength 0.96).
- He was slid in again (~t 10.2), and respawned at t 11.45 as the gust ended.
- HP went 3 → 1. A third fall would have killed him.
- At 0.3 the respawn lands in the gust too (strength 1.0, `gt` running through), but 66 px/s cannot move him.

This is the play evidence for `bugs/a-hazard-respawn-puts-ivo-back-into-the-gust-that-dropped-him` (filed from
code reading). The evidence and repro were added there and the severity raised. A restart at calm alone does not
remove the first idle fall: the respawn spot is 9-17 px east of the pool and the wind blows west, into it, so the next gust 6 s later pushes an
idle player in again.

**Guardian fights (10 %) cannot be played.** Every guardian arena in winter is covered (`lake_frost_arena`), where
`wind_at` is already 0. `fight_scale` has no effect in today's world, and only `weather_gust_test` covers it.

**What screenshots cannot show:** how the gust feels against the stick (latency, the strength of the push in the
hands), whether the rise is noticed in time as a warning, any sound (there is none yet, by decision), camera
smoothness while he is carried, and whether 20 s calms at 0.3 feel calm or empty.

## Ratings rationale

- **Fun 3 (low confidence, mostly inferred from logged timing).** At today's memory the weather is mostly
  scenery plus a jump modifier. The bridge gap becomes a timing beat with a cheap miss. Calms are long (20 s),
  so it rarely gets in the way. At memory 1 it bites: songs break, idle Ivo slides, and the lake bug punishes
  standing still.
- **Fluidity 3.** Walking in a grey gust is unaffected, which is smooth but makes the brace pose a lie. A
  song's own pulse shoves him at once. Cave and door restarts are seamless.
- **Aesthetics 3.** The calm/gust contrast is clean and the cave fade is soft. The dashes are thin and sparse,
  direction-less in stills, drawn over the ground, and the idle slide at memory 1 has no pose.
