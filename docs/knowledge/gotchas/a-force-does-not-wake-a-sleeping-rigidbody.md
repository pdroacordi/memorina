---
id: gotchas/a-force-does-not-wake-a-sleeping-rigidbody
type: gotcha
title: apply_central_force does not wake a sleeping RigidBody2D; square corners catch on tile seams
status: active
tags: [rigidbody, sleeping, apply-force, tilemap, seams, airflow]
related: [architecture/one-air-channel]
created: 2026-09-30
updated: 2026-09-30
source_files:
  - scenes/characters/components/airflow_body.gd
  - scenes/world/interactables/hanging_load/hanging_load.tscn
---

## Summary

Measured: a load at rest reported `sleeping=true` under a 253 px/s gale and never moved -
a force does not wake it. `AirflowBody` sets `sleeping = false` whenever the air drags.
Separately, a box sliding over a TileMapLayer stops dead on the internal edges between
tiles (and hops, vy 327); cutting the box's bottom corners (a `ConvexPolygonShape2D`)
lets it ride over them. A capsule would too, but cannot be stood on.
