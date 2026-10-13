---
id: features/rotating-spiral-stair
type: feature
title: Ivo climbs a spiral stair in the bell tower and the lighthouse while the tower turns around him
status: active
tags: [helix, stair, bell-tower, lighthouse, interior, movement-mode, projection, subviewport]
related: [systems/helix-stair, architecture/walkable-helix-stair, architecture/room-void-outside-the-shell, features/rooms-end-in-black, bugs/left-and-right-cannot-take-ivo-down-past-the-lighthouse-joint, bugs/descending-from-the-helix-head-runs-in-place-on-the-gallery-then-drops-a-turn, playtests/2026-10-11-bell-tower-helix, playtests/2026-10-11-lighthouse-helix]
created: 2026-10-13
updated: 2026-10-13
source_files:
  - scenes/world/interactables/helix_stair/helix_stair.gd
  - scenes/world/interactables/helix_stair/helix_end.gd
  - scenes/world/interactables/helix_stair/helix_math.gd
  - scenes/world/interactables/helix_stair/helix_steer.gd
  - scenes/world/interactables/helix_stair/helix_projection.gd
  - scenes/world/interactables/helix_stair/helix_faces.gd
  - scenes/world/interactables/helix_stair/helix_view.gd
  - scenes/characters/components/helix_rider_component.gd
  - scenes/characters/ivo/player.gd
  - resources/world/helix/helix_stair_shape.gd
  - resources/world/helix/helix_look.gd
  - resources/world/helix/bell_tower_helix.tres
  - resources/world/helix/bell_tower_look.tres
  - resources/world/helix/lighthouse_helix.tres
  - resources/world/helix/lighthouse_look.tres
  - scenes/world/rooms/home_village/contents/village_bell_tower.room
  - scenes/world/rooms/frost_edge/contents/lighthouse_interior.room
---

## Summary

In the bell tower and the lighthouse Ivo walks into the foot of a spiral stair and climbs by holding Up or the stair's direction. He stays at the stair's front on its axis while the stair, wall, window slits and bell turn around him; on the stair jump, roll, attack, doors, benches and the Memorina are refused. WORLD-26; the contract is `systems/helix-stair`.

## Details

- **The place.** `HelixStair` (legend `@`, `helix_stair.gd:1`) stands on the bottom floor; its cell's bottom-left corner is the axis base (`AXIS`, `:7`). It adds two `HelixEnd` zones, foot and head (`_end`, `:225`). Params: `shape` (`HelixStairShape`), `look` (`HelixLook`), `hand` (1 climbs toward the right).
- **The path.** `HelixMath.feet` (`helix_math.gd:11`) rises linearly with progress `u`; `HelixMath.stand` (`:16`) puts the feet on the tread top under the axis. Bell tower: 3.5 turns, 1120 px rise, 32 steps a turn (10 px risers), 11.0 s foot to head at 192 px/s.
- **Steering.** `HelixSteer.direction` (`helix_steer.gd:11`): Up or the hand side climbs, Down or the other side descends; a diagonal goes vertical when |y| >= 0.5.
- **The rider.** `HelixRiderComponent` (`scenes/characters/components/`, ungated) boards an end within `board_reach` (6 px), waits `regrab_delay` (0.3 s) after leaving, and each step writes a vertical velocity up the axis so `move_and_slide` keeps collision (`update`, `helix_rider_component.gd:78`).
- **The player.** `MotionState.STAIR` (`player.gd:83`) sits above knockback; every buffered press is dropped while riding (`player.gd:290`); `_try_board` (`:517`) boards only on the floor with nothing else holding him; `frame_bias()` (`:460`) makes the camera follow the steady rise, not each riser.
- **The view.** `HelixStair._build_view` (`helix_stair.gd:207`) adds a `HelixView`: a nearest-filtered SubViewport at art resolution, shown as a Sprite2D at scale 2 and z -15 (`helix_view.gd:7-9`), behind the room's tiles. `refresh` (`:63`) rebuilds `HelixFaces.build` (`helix_faces.gd:32`) only when the tower's angle or the camera's centre height changed. Every face is placed by `HelixProjection.project_polar` (`helix_projection.gd:23`); the shell's inner walls stand at `silhouette` (`:27`), 127.95 px from the axis.
- **One tower, several flights.** A stair whose foot stands on another's head, same axis, same hand, same parent, joins it (`_link`, `helix_stair.gd:179`). Only the lowest stair keeps the angle (`angle`, `:140`); `turn_below` and `rise_below` (`:160`, `:164`) keep the wall courses continuous across the joint.
- **Where.** `village_bell_tower`: 1x4 screens at (9600, 12000), one stair, a plank gallery at the head, the double-jump alcove 6 rows above it. `lighthouse_interior`: 1x4 screens at (24000, 12000), two flights of 2 turns each (640 px, 6.3 s) at rows 44 and 24, joined at the mentor's floor (row 25), stone and iron look with a well-side rail.
- **Validation.** `HelixStair.check` (`helix_stair.gd:39`) runs on every map from `room_files_test`; the reach audit joins foot and head both ways through `reach_ends` (`:172`).
- **Tests.** `tests/scenes/world/interactables/helix_stair/`, `tests/scenes/characters/components/helix_rider_component_test.gd`, `tests/scenes/characters/ivo/player_helix_test.gd`. Timelines: `tools/playtest/scripts/bell_tower_helix_climb.json`, `lighthouse_helix_climb.json`.

## Why

- The request: "the player goes spinning and it almost looks like an optical illusion" (user, 2026-10-10). The first build moved Ivo across a static ribbon and was rejected: "there should be something more 3d like" (user, 2026-10-11).
- Flat-shaded polygons drawn at art resolution replace textures because a texture rescaled every frame by perspective shimmers under nearest sampling; one GDScript projection serves the view, `check` and the tests. Options and rejected alternatives: `architecture/walkable-helix-stair`, "Revision (2026-10-11)".

## Gotchas / pitfalls

- Nothing the view draws may be in front of Ivo, and the view has no clock: the angle comes from the rider, the eye from the camera (`systems/helix-stair`, Never break).
- A shape change must still pass `HelixStairShape.problems()` and `HelixStair.check`; the shell's inner walls must move with the silhouette.
- At a joint each end keeps its own stair's rules; left and right alone must reach every floor (`bugs/left-and-right-cannot-take-ivo-down-past-the-lighthouse-joint`).
- A body resting on a one-way gallery cannot be pushed down into it; the rider teleports onto the tread instead (`gotchas/a-body-resting-on-a-one-way-cannot-be-pushed-down-into-it`).
- A helix room holds no enemies or hazards: a knockback beside the foot would push Ivo into the stair's footprint.
