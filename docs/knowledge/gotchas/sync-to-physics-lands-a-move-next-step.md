---
id: gotchas/sync-to-physics-lands-a-move-next-step
type: gotcha
title: An AnimatableBody2D with sync_to_physics shows a moved transform only after the next physics step
status: active
tags: [animatable-body, sync-to-physics, transform, tests, floater, mechanism]
related: [architecture/the-water-level-moves]
created: 2026-09-30
updated: 2026-09-30
source_files:
  - scenes/world/interactables/floater/floater.gd
  - scenes/world/interactables/gate/mechanism.gd
---

## Summary

With `sync_to_physics = true` (needed so a moving platform carries whoever stands on
it), writing `global_position` hands the move to the physics server; reading
`global_position` back in the same frame still returns the old value. In play this is
invisible (one move per physics frame), but a synchronous test that sets and reads back
sees nothing move.

## How to handle it

Keep the target as the object's own state and answer from it: `Floater.ride_y()` /
`is_afloat()`, `Mechanism.is_moved()` (its progress). Test those, not the transform.
