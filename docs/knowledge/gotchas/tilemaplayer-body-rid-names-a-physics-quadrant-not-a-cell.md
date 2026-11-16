---
id: gotchas/tilemaplayer-body-rid-names-a-physics-quadrant-not-a-cell
type: gotcha
title: TileMapLayer.get_coords_for_body_rid returns the physics quadrant, not the tile, with quadrant size above 1
status: active
tags: [tilemaplayer, physics, physics-quadrant, collision, godot-4-5]
related: [bugs/ivo-steps-and-soft-landings-are-silent-on-room-ground]
created: 2026-11-16
updated: 2026-11-16
source_files:
  - scenes/characters/components/step_surface_probe.gd
---

## Summary

Since Godot 4.5 a `TileMapLayer` merges its tiles' collision into one body per physics quadrant
(`physics_quadrant_size`, default 16). `get_coords_for_body_rid(collision.get_collider_rid())`
then returns that quadrant's coordinates, not the coordinates of the tile that was hit.

## Details

Measured in 4.7.2 headless. A 10 px body was dropped onto a 32 px cell layer at cells (3,3),
(25,3) and (37,3). The returned coordinates were (0,0), (1,0) and (2,0), which are `cell / 16`.
`physics_quadrant_size` read 16 and was never set. The engine's class reference built into the
binary has no description of this method, so the old "tile coords" reading still looks correct.

To find the tile that was hit, convert the contact point:
`layer.local_to_map(layer.to_local(collision.get_position() - collision.get_normal() * 0.5))`.
Alternatively, set `physics_quadrant_size = 1` on that layer, which costs one body per tile.

Probe harness pitfall: `RoomMap.CELL_PX` is 32. A probe that places bodies at 64 px cells starts
them below the ground and reads "no collision".
