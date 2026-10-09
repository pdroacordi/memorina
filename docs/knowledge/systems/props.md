---
id: systems/props
type: system
title: Props and ambient motion - set dressing behind the play plane, moving only on the memory clock
status: active
tags: [props, ambient, memory-clock, greyhush, inhabitants, region-presence]
related: [architecture/props-and-ambient-life, systems/greyhush, systems/backdrops, systems/foreground, systems/world]
created: 2026-10-09
updated: 2026-10-09
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
- **A prop sheet:** frames side by side, season bands stacked; nature props wear `prop_seasonal_material.tres` (3 bands, `(2, 0, 1, 0)`), built props none. Row 0 is band 0, so `frame` 0..hframes-1 never leaves it.
- **`AmbientMotion`** (child Node of the prop's Sprite2D, PAUSABLE even under an ALWAYS parent): each physics frame, on screen and visible, it samples `MemoryField.sample` at the prop (plus `sample_offset`), advances its own time by `delta * memory` (`AmbientMath.advance`) and writes `frame` (`AmbientMath.frame_at`, with an optional `sequence` and a stable per-position `phase`). Below `stop_threshold` (0.2: "Stop below 0.2 memory", user, 2026-10-09) it holds its frame; a pulse resumes it from there. Off screen nothing advances. It asserts it is never under a `Character`.
- **`RegionPresence`** (child Node): shows the parent while `Region.current_baseline() >= min_baseline`, re-applied on `Region.memory_changed`. Villagers who leave as the village falls to 0.6 get 0.7 (WORLD-11).
- **Rotation** (windmill sails, the water wheel) is baked into frames on the 1x grid ("Baked pixel frames", user, 2026-10-09); the bake tool comes with WORLD-11's art.
- **Lit windows, flames, smoke** are frames greyed like everything else: only characters escape the grey.
- **Today:** a placeholder 4-frame flag in `trials_solstice/door_trial` (memory 0.35) waves on the memory clock; `tools/playtest/scripts/props_flag.json`.
