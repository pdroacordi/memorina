---
id: bugs/water-that-returns-leaves-its-dry-floor-as-safe-ground
type: bug
title: A floor the water was held off (Redoma) or had not reached yet (a dry Chuva basin) is recorded as safe ground, and the respawn lands under the returning water
status: fixed
severity: high
tags: [safe-ground, respawn, hazard, water, redoma, chuva, rain-basin, hold-out]
related: [bugs/roll-iframes-hide-the-water-so-the-pool-floor-becomes-safe-ground, bugs/temporary-song-floors-are-remembered-as-safe-ground, architecture/the-water-level-moves, architecture/the-bell-jar-closes-once, architecture/hazard-respawn-on-safe-ground]
created: 2026-09-30
updated: 2026-09-30
source_files:
  - scenes/world/environment/water/water_body.gd
  - scenes/characters/components/safe_ground_tracker.gd
  - scenes/characters/ivo/player.gd
  - scenes/world/interactables/rain_basin/rain_basin.gd
---

## Summary

`SafeGroundTracker._in_hazard()` refuses a spot only while a hazard shape covers it.
`WaterBody` turns the hazard off where the water is held out (`_refresh_dry` and
`_rebuild_runs`) and while a basin is shallow (`_refit_hazard`, `shallow`). So the
dried floor of a well under a Redoma, and the floor of a dry Chuva basin, are recorded
as firm ground. When the water comes back, `respawn()` returns Ivo to that spot, which
is now under water.

## Symptom

Found in review, not reproduced in engine. The mechanism follows directly from the code.

- Ivo walks the well floor dried by a Redoma (the 2026-09-30 redoma-well playtest does
  exactly this). The shell contracts and the water returns over him, so he falls in.
  The last safe spot is the one he was standing on a frame earlier, which is now wet.
  He is respawned inside the hazard shape he never left, so `body_entered` does not
  fire again. He stands and walks on the bottom under water, which breaks "Ivo does not
  swim". If the shell is still contracting, each change to the dry columns rebuilds the
  run shapes. The removed and re-added shapes re-fire `body_entered`, so he falls again,
  once per rebuild.
- In a dry `RainBasin` he plays Chuva. The level passes `hazard_depth`, the hazard is
  enabled around him and he sinks. He is respawned on the basin floor, still inside the
  same shape, and stands under water.
- Common enemies (`Character.receive_hazard` has no `_sinking` guard) take another hit
  of hazard damage on every run rebuild while they stand in the water.

## Root cause

- `water_body.gd:404-405, 413`: the hazard shapes are disabled where the column is dry
  and while `size.y <= hazard_depth`.
- `safe_ground_tracker.gd:52, 65-71`: "not inside a hazard" is tested only against the
  shapes enabled right now.
- `water_body.gd:415+`: `_rebuild_runs` frees and re-creates every run shape whenever
  the dry set changes. That re-fires `body_entered` for every body already in the
  water.

## Fix

Open. Options, in order of preference:
1. The tracker also refuses a spot inside a water body's level range
   (`WaterBody.at(node, point)` non-null and the spot below its painted top
   `level_range().x`), whatever the current level or hold-out.
2. Keep the hazard shapes and gate the decision instead: `HazardZone` asks the body of
   water whether the column is wet before it calls `receive_hazard`.
Separately, resize the run shapes in place instead of freeing them, so a body already
in the water is not re-entered.

## Prevention

"Never a spot inside a hazard" has to mean "where water CAN be". A hazard that is
switched off is not the same thing as a floor that is safe.

## Resolution (2026-09-30)

Fixed: `SafeGroundTracker` refuses any spot inside a water body's painted level range (`WaterBody.at`), dry or held out. The hazard no longer frees its shapes: a held disc reshapes reused `CollisionPolygon2D` outlines, and `HazardZone` takes a body once per stay, forgetting it only a frame after it stops overlapping, so a reshaped outline cannot take someone twice.
