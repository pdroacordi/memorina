---
id: architecture/weight-and-presence
type: architecture
title: Sombra and Soltar act through weight, presence and release, not per-puzzle rules
status: active
tags: [sombra, soltar, weight, presence, pressure-plate, seesaw, enemy-sight, pulse-effect]
related: [architecture/one-air-channel, architecture/played-pulses-hold-in-a-pause, bugs/room-entity-links-depended-on-file-order]
created: 2026-09-30
updated: 2026-09-30
source_files:
  - scenes/world/interactables/weight/weight.gd
  - scenes/world/interactables/weight/weight_sensor.gd
  - scenes/world/interactables/gate/mechanism.gd
  - scenes/world/interactables/seesaw/seesaw.gd
  - scenes/world/interactables/releasable/release_state.gd
  - scenes/world/memory/song_effects/shadow/cast_shadow.gd
  - scenes/characters/components/enemy_sight.gd
---

## Summary

A burned shadow "counts as the hero being there" by being made of the same parts the
hero is: a `Weight` (plates and seesaws count it) and a node in `EnemySight.PRESENCE`
(creatures go for it). Soltar is one `Releasable` + `ReleaseState` rule on any parent.
No plate knows about shadows and no shadow knows about plates.

## Details

- `WeightSensor` sums `Weight` children of bodies AND areas: the shadow is an area (its
  `Presence` is a `Hurtbox` with a `Weight`), a load is a body.
- `EnemySight` keeps two answers: `player` (Ivo alone, for guardians) and
  `visible_presence()` (nearest in plain sight, for common enemies, chosen once per
  tick in `EnemyAI.tick`).
- The shadow breaks on the first blow because it IS a hurtbox on the Player Hurtbox
  layer: enemy hitboxes need no new mask.
- `ReleaseState` returns a thing when the LAST pulse leaves it, deferred while held.
  Leaving includes the thing being carried out of the disc.

## Why

The design (02 section 7.4) wants compositions to fall out of shared systems. Sombra +
Soltar (a shadow on one plate, a load on the other) needed no code at all.

## Gotchas / pitfalls

- A seesaw with a centred pivot cannot hold Ivo up with his own shadow: equal masses at
  equal distances balance. Use `pivot_at` so the shadow's arm is longer.
- `Mechanism` follows ONE trigger; a second input is a lock, not a second trigger.
