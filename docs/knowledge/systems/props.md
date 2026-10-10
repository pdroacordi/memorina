---
id: systems/props
type: system
title: Props and ambient motion - set dressing behind the play plane, moving only on the memory clock
status: active
tags: [props, ambient, memory-clock, greyhush, inhabitants, region-presence]
related: [architecture/props-and-ambient-life, systems/greyhush, systems/backdrops, systems/foreground, systems/world]
created: 2026-10-09
updated: 2026-10-10
source_files:
  - scenes/world/environment/props/ambient_math.gd
  - scenes/world/environment/props/ambient_motion.gd
  - scenes/world/environment/props/region_presence.gd
  - scenes/world/environment/props/prop_seasonal_material.tres
---

# Props and ambient motion

**Never break:** a prop never collides, never carries gameplay and never joins a `CanvasPass`; ambient motion runs only on the memory clock, through `AmbientMotion` (never an `AnimationPlayer` on scaled time, which keeps moving in the grey).

Design 04 sections 5-6, WORLD-08 (WORLD-10's villagers and animals are props of the same kind). Plan, options and the village prop list: `architecture/props-and-ambient-life`.

- **Placement.** Props are hand-placed `Sprite2D` scenes under a `Props` Node2D (`z_index` -10) in a room's contents scene, after `Backdrop` and before `RoomMap`. Draw order by z: `Backdrop.Z` -30, WORLD-07's `[back]` walls -20, props -10, ground and entities 0, water 50. A surface Ivo stands on is a `.room` cell, never a prop.
- **A prop sheet:** frames side by side, season bands stacked; nature props wear `prop_seasonal_material.tres` (3 bands, `(2, 0, 1, 0)`), built props none. `vframes` equals the band count and row 0 is band 0, so `frame` 0..hframes-1 never leaves it; every `sequence` entry stays below `hframes` (a higher one shows another season's art).
- **`AmbientMotion`** (child Node of the prop's Sprite2D, PAUSABLE even under an ALWAYS parent): each physics frame, on screen and visible, it samples `MemoryField.sample` at the prop (plus `sample_offset`), advances its own time by `delta * memory` (`AmbientMath.advance`) and writes `frame` (`AmbientMath.frame_at`, with an optional `sequence` and a stable per-position `phase`). Below `stop_threshold` (0.2: "Stop below 0.2 memory", user, 2026-10-09) it holds its frame; a pulse resumes it from there. Off screen nothing advances. It asserts it is never under a `Character`.
- **`RegionPresence`** (child Node): shows the parent while `Region.current_baseline() >= min_baseline`, re-applied on `Region.memory_changed`. Villagers who leave as the village falls to 0.6 get 0.7 (WORLD-11).
- **Rotation** (windmill sails, the water wheel) is baked into frames on the 1x grid ("Baked pixel frames", user, 2026-10-09); the bake tool comes with WORLD-11's art.
- **Lit windows, flames, smoke** are frames greyed like everything else: only characters escape the grey.
- **Facades** (WORLD-11; "The doors in the middle of nowhere are just placeholders?", user, 2026-10-10; the board in the running game: "Approve as shown (Recommended)", user, 2026-10-10). Every door on a village street stands in its building's front: `scenes/world/environment/props/village/<id>_facade.tscn` (`ivo_house`, `bell_tower`, `tavern`, `elder_house` in the square; `bakery`, `empty_house` in the lane), a still `Sprite2D` placed at its door's feet (the `E` cell's bottom centre), its offset minus the doorway's sill centre. The art draws a dark 16x32 art px doorway recess; the `Door` entity's sprite (32x64, shut / sealed, no outline) fills it. Fronts are cut from one Codex sheet by `tools/art/cut_facades.py`, each scaled so its doorway is 64 px tall (2x density, one 20-colour palette). `facade_doors_test` holds both ways: a facade stands on a door, and every door in a room with the `village_valley` backdrop stands in a facade. The tavern's door moved from col 36 to 38 so its front clears the well (cols 28-31). Window lights, smoke and signs are separate props (`architecture/props-and-ambient-life`).
- **Today:** a placeholder 4-frame flag in `trials_solstice/door_trial` (memory 0.35) waves on the memory clock; `tools/playtest/scripts/props_flag.json`.
- **Shared stop threshold** (2026-10-10): `AmbientMath.STOP_THRESHOLD` (0.2) is the one constant props (`AmbientMotion.stop_threshold`) and grass (`systems/grass`) stop below.
