---
id: systems/air
type: system
title: Air: one physical channel for wind, currents and the gale
status: active
tags: [air, wind, gale, airflow]
related: [architecture/one-air-channel]
created: 2026-10-02
updated: 2026-10-07
source_files: []
---

# Air: one physical channel for wind, currents and the gale

Moved verbatim from `CLAUDE.md` ("Air") on 2026-10-02.

Design 03 sections 5.3-5.4 and 6.1: wind, a current, a song's gale and the weather push "pelo mesmo canal fisico". That channel is **`Airflow`** (`scenes/world/environment/wind/`, in `game.tscn` under `World`, found by group): `AirflowSource`s register and `sample(point)` sums them into a **velocity** (px/s), scaled by the memory at the point - air in the grey has stopped. `AirflowShelter`s (the bell jar's shell, later benches) still the air inside them.

- **Wind is a velocity the air carries, never a force.** `AirflowBody` (a component, runs at physics priority -1 so there is no frame of lag) samples the air at its body and calls `Character.push(wind)`, which accumulates `carry()` for the frame; the body's own motion decides what it means. `LocomotionComponent.ground_update/air_update(delta, axis, wind_x)` steer toward input speed PLUS the wind, so a tailwind carries a jump further and a headwind shortens it - bounded, where an added force against capped braking was either nothing or a runaway. On the ground, feet ignore anything under `LocomotionStats.wind_deadzone` and slide at `wind_grip` of the excess, so a breeze never breaks a standing performance and a gust does, through the existing `is_still()` (design 5.4 item 3, no new rule). Vertical air is `lift_update`. A RigidBody2D is dragged toward the wind's velocity along it. Guardians have no `AirflowBody` (weather drops in a boss fight, design 5.5).
- **Ivo is half sheltered while the instrument is out** (`Player.memorina_shelter`, pushed into `AirflowBody.exposure`; design 5.4 item 2), and leans into a wind he walks against (the `brace` clip, `Player.is_bracing()`).
- **`WindZone`** is a natural current: a box standing on its cell (room map `W`), a direction, a speed and a `WindProfile` (calm/rise/gust/fall - the calms are the window to play in). It draws directional streaks and leaves in layers, so it reads as the world's doing. A FREEZE pulse over it stops it and its streaks hang, icy.
- **Vendaval (`GALE`) is `GaleField`**, the song's `PulseEffect`: a `GaleWind` blowing ONE WAY across the whole disc - the way Ivo faced when the song ended (`ColorPulse.performer`'s `facing`; the user's decision, 2026-09-30) - horizontally, still in an eye (48 px), peaking a third of the way out and gone at the clean disc (`GaleShape`, pure and tested). Played into a current it simply adds to it; aimed wrong, it blows the load away from the plate. It reads as the SONG, not the world, by colour and by bounds rather than by geometry: curling pixel-art gusts, dashes and leaves in the season's tint (`SpriteBursts`, clipped to the season mask), living only inside the pulse and dying with it.
- **`SpriteBursts`** (`song_effects/bursts/`) is the one pool for short pixel-art sprites a song throws off - a gust, a splash - each a `SpriteStrip` resource (`resources/world/effects/`: texture, frames, life, fps, anchor, stepped fade), drawn at whole pixels in world coordinates on the world's clock. The strips are drawn by `tools/art/draw_procedural_sprites.gd`.
- **Wind moves water**: `WaterBody` samples the air over its columns with its memory rates and drags the surface downwind (`WaterProfile.wind_stress`) - a slope while it blows, a crest the springs carry when it drops, which Congelar will catch into a ramp.
- **Weather in a grey place is weak and slow**: a `WindZone`'s push and its clock both scale with the memory over it, so a puzzle that needs its wind outside a pulse must stand in a remembered spot. The winter trial's squall has its own `MemorySource` (`SquallMemory`, strength 1) for that; at the trials' 0.35 its gusts never broke a song (`bugs/the-winter-squall-never-breaks-a-song-at-the-trials-memory`).
- **Puzzles are sized by `JumpReach` with the same wind** (`JumpReach.wind`, steered exactly as `air_update` does); `tests/scenes/world/rooms/trials/autumn_trial_test.gd` proves the autumn chasm beats a jump, the current alone and the gale alone, and yields to the gale played into the current.
