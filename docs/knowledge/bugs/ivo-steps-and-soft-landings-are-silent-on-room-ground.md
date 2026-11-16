---
id: bugs/ivo-steps-and-soft-landings-are-silent-on-room-ground
type: bug
title: Ivo's footsteps and soft landings are silent (or the wrong surface) on every room's ground
status: fixed
severity: high
tags: [audio, footsteps, tilemaplayer, physics-quadrant, snd-01]
related: [systems/sound-effects, architecture/sound-effects-system, gotchas/tilemaplayer-body-rid-names-a-physics-quadrant-not-a-cell, playtests/2026-11-16-snd01-sound-effects]
created: 2026-11-16
updated: 2026-11-16
source_files:
  - scenes/characters/components/step_surface_probe.gd
  - scenes/world/rooms/maps/room_map_node.gd
---

## Summary

`StepSurfaceProbe.surface_of` maps a floor collision on a room's `Solid` layer to a cell with
`TileMapLayer.get_coords_for_body_rid`, which in 4.5+ returns the physics quadrant (16x16 cells),
not the cell. The lookup reads the wrong cell, so the floor is NONE and the step is silent.

## Symptom

Found in the SND-01 review (2026-11-16), measured in 4.7.2 headless. Bodies landed on a parsed
room's `Solid` layer at cells (3,3), (25,3) and (37,3). `get_coords_for_body_rid` returned
(0,0), (1,0) and (2,0), and `surface_of` returned NONE where `surface_at` gives STONE, SNOW and
SNOW. In game, every step and soft landing on room ground is silent. If a quadrant index happens
to fall on a solid map cell, the surface is wrong instead. Bodies that declare `step_surface`,
and the STONE default, still work.

## Root cause

`scenes/characters/components/step_surface_probe.gd:22` passes
`layer.get_coords_for_body_rid(rid)` to `RoomMapNode.surface_at`. The `Solid` layer
(`room_map_node.gd:257`) keeps the default `physics_quadrant_size` of 16, so each collision body
covers a quadrant. `step_surface_probe_test` calls `surface_at` and `surface_of(body, RID())`
separately and never builds a real tile collision, so it passes. `ivo_sounds_test` stands Ivo
on a plain body (STONE).

## Fix

Not fixed. Derive the cell from the contact, for example
`RoomMapNode.cell_at(collision.get_position() - collision.get_normal() * 0.5)` (half a pixel
into the floor), or use the tile's `ground` custom data plus a look lookup by point.
`physics_quadrant_size = 1` would also work, but it gives up the merged-shape optimisation for
every room.

## Prevention

Add a test that drops a `CharacterBody2D` onto a `RoomMapNode` built from a `.room` string
(cells 32 px), at a cell outside quadrant (0,0), and asserts the probe's surface after
`move_and_slide()`. Not yet added.

## Revision (2026-11-16): confirmed in game

Seen in the playtest (`playtests/2026-11-16-snd01-sound-effects`, build b191ba84). The cue log's cross-check printed
`surf=NONE true=STONE cell=(24, 5) rid_coords=(1, 0)` on threshold_bridge. There, and on lake_shore (5 s of running),
no step cue fired. On frost_shore, steps sounded for x < 8832 (quadrant (0,0) maps to cell (0,0), a stone wall) and
stopped from x 8834. The song trials sound correct only because their origins put the floor on layer row 0. Re-check
on lake_shore with `tools/playtest/scripts/snd01_boar_and_real_floors.json` under `snd01_cue_log_driver.gd`.


## Fix (2026-11-16)

`StepSurfaceProbe.surface_of(collider, point)` takes the contact point pushed `INSIDE_FLOOR` (1 px) into the floor against the collision normal, and the room answers `surface_at(cell_at(point))`. `get_coords_for_body_rid` is no longer used. `step_surface_probe_test.test_a_body_landing_on_room_ground_reads_the_cell_under_it` drops a body onto columns 3, 18, 25 and 37 of a 40-column room (three physics quadrants) and checks snow and stone.
