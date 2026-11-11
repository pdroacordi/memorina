---
id: bugs/a-standing-brace-plays-the-push-walk-cycle-in-place
type: bug
title: The MEM-16 standing brace at a held lip plants his trailing boot on air (the stride in place is fixed by brace_stand)
status: resolved
severity: low
tags: [animation, brace, wind, gust, mem-16, ledge, pose]
related: [playtests/2026-11-11-mem16-gust-feel, systems/animation, systems/air, bugs/a-standing-brace-cuts-the-memorina-lower-clip]
created: 2026-11-11
updated: 2026-11-11
source_files:
  - scenes/characters/ivo/player_animation_resolver.gd
  - scenes/characters/ivo/ivo.tscn
  - scenes/characters/ivo/player.gd
---

## Summary

The standing brace added by MEM-16 (`player_animation_resolver.gd`, idle branch `if _player.is_bracing(): return BRACE`)
plays the same `brace` clip as walking into the wind. That clip is the `push` sheet (`ivo.tscn`, `Animation_brace`,
length 1.0, `loop_mode = 1`), a stepping cycle. With velocity 0 the legs keep stepping.

## Symptom

- threshold_bridge, `mem05_brace_and_streaks.json` at memory 0.3: after the headwind walk Ivo stands at x 6878.2,
  velocity 0, facing east, from t 26.9 to 29.0. Four frames 0.05-0.1 s apart show the stride cycling: wide stance, then
  feet together, the back boot moving 10+ game px (`playtests/screenshots/2026-11-11-mem16-gust-feel/standing_brace_marches_in_place.png`).
- At memory 1 an idle Ivo facing into the gust slides west at 52 px/s in the same clip, so the legs step east while the
  body moves west. This is inferred from the clip and the logged velocity: 0.5 s frames cannot show the cycle's motion.
- Parked at a downwind lip (`mem05_east_lip_mem1.json`, forced memory 1, x 7136.0 from t 7.94 to the gust's end), the
  pose leans east with only the front toe on the corner (~11 game px). The back boot is planted 12-24 px out over the
  ravine, as if standing on air (`lip_hold_feet_over_void.png`, red line = the lip). In the idle pose after the gust, the
  feet straddle the corner.

## Root cause

MEM-16 made `is_bracing()` true for a standing Ivo facing the wind, but there is no standing brace pose. The resolver
falls back to the walking one. `_hold_the_lip` parks the feet' centre on the lip, which is right for collision but puts
the brace sprite's trailing leg past the edge.

## Fix (proposed)

A standing brace pose, held or slowly breathing, with both feet planted (a new clip, or a frame range of the push
sheet). Optionally, if the lip stop should look secure, stop the slide when the trailing foot, not the centre, reaches
the lip. That changes collision feel, so playtest it first.

## Prevention

A new resolver condition that can be true at velocity 0 needs a clip that reads at velocity 0. Check a looping clip
against the logged velocity in a playtest before reusing it.

## Re-check 2026-11-11 (17:14 code), reopened

Played in `playtests/2026-11-11-mem16-gust-feel` (Re-check section), forced memory 1, threshold_bridge east lip.

- **Fixed: the stride.** A standing Ivo facing the wind plays `brace_stand` (push frame 7 held). Every logged frame from
  t 6.60 to 10.57 is `ivo_push.png#7`, so there is no stride and no moonwalk while slid. Walking still plays `brace`.
- **Fixed for idle: the lip stop.** `_hold_the_lip` now stops him at x 7147.0-7147.3 with `body_rect` 7136.0..7158.0,
  the downwind edge on the lip at x 7136, facing east or west. Idle, both boots are on the stone.
- **Not fixed: the braced boot.** Facing east into the gust at the lip, `brace_stand`'s trailing boot spans window
  x 392..~410 against the lip at 426, **8-17 game px over the ravine**, for the whole gust
  (`playtests/screenshots/2026-11-11-mem16-gust-feel/recheck_brace_stand_at_lip_vs_idle.png`). Frame 7's stance is
  ~45 game px wide against the 22 px body, and the trailing foot is always the downwind one. So this is exactly the
  case the brace plays in at a lip. The lip probe uses `body_rect()`, not the pose's footprint.
- **Fix direction:** at a held lip (`_lip_held_frame` this frame), either play a narrower planted frame (feet within
  the body rect), or probe at the brace pose's trailing-foot extent (~23 px behind the centre) while bracing. That
  stops him ~12 px further back. Playtest the second, because it changes where an idle Ivo ends up when the gust ends.

## Fix of the rear boot (2026-11-11)

While he braces standing, `_hold_the_lip` probes under the rear boot's heel, `Player.BRACE_HEEL` (28 game px behind his x, measured on push frame 7 and pinned by `ivo_sheet_test.test_the_standing_brace_heel_is_where_the_lip_hold_looks`), or the capsule edge if that is further; `player_wind_test.test_a_braced_slide_stops_with_the_rear_boot_on_the_stone`. The one-frame cut idle -> `brace_stand` is left as is (re-check note, subjective).
