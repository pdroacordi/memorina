---
id: systems/helix-stair
type: system
title: Helix stair - the tower turns around Ivo as he rides up its axis; projected flat-shaded geometry at art resolution
status: active
tags: [helix, stair, interior, bell-tower, movement-mode, projection, subviewport, room-map, void]
related: [architecture/walkable-helix-stair, architecture/room-void-outside-the-shell, systems/rooms, systems/world, systems/roots-and-climbing, systems/animation, systems/input, systems/greyhush, playtests/2026-10-11-bell-tower-helix]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/interactables/helix_stair/helix_math.gd
  - scenes/world/interactables/helix_stair/helix_steer.gd
  - scenes/world/interactables/helix_stair/helix_projection.gd
  - scenes/world/interactables/helix_stair/helix_faces.gd
  - scenes/world/interactables/helix_stair/helix_view.gd
  - scenes/world/interactables/helix_stair/helix_stair.gd
  - scenes/world/interactables/helix_stair/helix_end.gd
  - scenes/characters/components/helix_rider_component.gd
  - resources/world/helix/helix_stair_shape.gd
  - resources/world/helix/helix_look.gd
  - resources/world/helix/bell_tower_helix.tres
  - resources/world/helix/bell_tower_look.tres
  - scenes/characters/ivo/player.gd
  - tools/art/cut_board_prop.py
---

# Helix stair

**Never break:** Ivo's plane is the 2D world. Ivo rides the stair's axis at its front and nothing the view draws is ever in front of him; the tower turns by φ (his progress while riding, 0 at the foot, `head_u` at the head) and only `HelixView` draws the stair, wall, slits, posts, floor top and bell, all placed by one projection, `HelixProjection`, which `HelixStair.check` and the tests use too. The view has no clock: φ comes from the rider, the eye from the camera.

WORLD-26, design 04 §3.1. Plan, options and the revision: `architecture/walkable-helix-stair` ("Revision (2026-10-11): the rotating helix"); the shell's void: `architecture/room-void-outside-the-shell`.

## Decisions

- "Walkable helix (Recommended)" (user, 2026-10-10), from "the tower could be taller. And inside look something more like this (image attached) look how interesting it is to get up those stairs. something that would animate like the picture attached and the player goes spinning and it almost looks like an optical illusion" (user, 2026-10-10). The reference images and the later video are described in words only and never uploaded.
- Jump on the stair: "Nothing (Recommended)"; height: "4 screens (Recommended)"; the lighthouse stair: "Stone and iron (Recommended)" (user, 2026-10-11). The Memorina is refused on the stair (orchestrator's call, 2026-10-11).
- The first version (Ivo travelling left and right along a static ribbon, a ForegroundPass cover, darker far runs) was rejected: "And the spiraling is not working quite well, there should be something more 3d like" (user, 2026-10-11). The revision turns the tower around him.
- The top landing: "Floor across (Recommended)" (user, 2026-10-11): a plank gallery across the shell that Ivo rises through at the centre.
- The style board `tools/art/sources/bell_tower_board_codex.png`: "Approve (Recommended)" (user, 2026-10-11). Its colours are the `HelixLook`; the bell is the one sprite cut from it.

## How it works

- **Shape** (`HelixStairShape`; bell tower values): `wall_radius` 144, `walk_radius` 96 (Ivo's plane), `inner_radius` 48, `pitch` 320, `turns` 3.5 (head rise 1120 px), `steps_per_turn` 32 (riser 10 px), `eye_distance` 750, `speed_scale` 1. `problems()`: inner < walk < wall < eye, head rise a multiple of 32 px, at least 8 steps a turn, `steps_per_turn` × `turns` a whole number of steps (else the head is not the last tread's top).
- **Path** (`HelixMath`). The axis height `feet(u)` = (0, -pitch·u/TAU) rises linearly; ω = run_speed·speed_scale / walk_radius, so the front tread passes under him at his run speed: 2.0 rad/s, 102 px/s up, 11.0 s foot to head at 192 px/s. Step i spans u in [iΔ, (i+1)Δ) with its tread top (i + 0.5) risers up. **The feet stand on the tread under the axis** (`stand(u)`: the floor at the foot, the gallery at the head): each 10 px riser is climbed in the one step the next tread passes under him, so his feet are on a tread top every frame ("Many things on the game seem to just be flaoting. ivo while running doesn't touch the ground.", user, 2026-10-11). `Player.frame_bias()` (the gap between `feet` and `stand`, within 5 px) makes the camera, and so the view's eye, follow the steady rise, not the risers.
- **Projection** (`HelixProjection`). β = θ - φ; view point (hand·r·sin β, y, r·cos β); k = (D - walk)/(D - z); screen = (x·k, eye + (y - eye)·k). Ivo's plane maps 1:1 for every eye and φ. The wall's silhouette half-width R(D - walk)/sqrt(D² - R²) is 127.95 px: the shell's inner faces stand there.
- **Faces** (`HelixFaces`, pure). The wall's inner surface where cos β < R/D, in 24 px courses of 40-64 px blocks (hash-varied tone, mortar outline, a highlight line), then posts, beams and slits on it, then the floor's top behind the cut, then every step face (tread, soffit, riser, back, inner and outer stringer, the section by Ivo's plane) clipped to z <= walk, back faces culled, sorted far to near, with the outer stringer cut by Ivo's plane as a solid band (`band_depth` 28 px) whose top runs through the risers' feet, under every tread section, so it never rises over his feet; last, the gallery's edge (`gallery_depth` 18 px, plank joints every 24 px) across the shell under the plank tiles. Only faces that can show in the camera's window are built.
- **View** (`HelixView`, built by `HelixStair`). A transparent SubViewport the size of the shell's interior in art px (128 x 720 for the bell tower), nearest filter, drawn with `draw_colored_polygon` and 1 px `draw_polyline` (a polygon that does not triangulate is skipped) and `UPDATE_ONCE` after each redraw; a Sprite2D at scale 2 on the interior's top-left at z -15, behind the room's tiles (0) and in front of the backdrop. It redraws only when φ or the eye changed. Root-canvas world art, so the greyhush greys it. The bell is drawn at its axis-depth size and only translated.
- **Steering** (`HelixSteer.direction`, static). Up or the hand side climbs, Down or the other side descends, |y| >= 0.5 wins a diagonal. No latch. Facing = hand × direction.
- **The place** (`HelixStair`, legend `@`). On the bottom floor, its cell's bottom-left corner the axis base. Params `shape` (required), `look`, `hand`. Two `HelixEnd` zones (12 x 48 px, physics layer 3) on the axis at the foot and the head. `angle()`, `set_rider_angle(u)`, `clear_rider(at_head)`.
- **The rider** (`HelixRiderComponent`, generic). Boards an end within `board_reach` (6 px) of its x: the foot on Up or the hand side, the head on Down or the other side; a horizontal press held since the last dismount boards nothing until it changes; `regrab_delay` 0.3 s after any release. Each step it writes velocity = (axis.x - x, stand.y - y)/delta, a vertical sweep up the axis column, so `move_and_slide` keeps collision. A step down from a floor (the one-way gallery at the head) is a `Character.teleport_body` onto the tread instead, because a body resting on a one-way cannot be moved down into it (`gotchas/a-body-resting-on-a-one-way-cannot-be-pushed-down-into-it`); `check()` keeps solids out of the column, so only a one-way can stop a descent. If the body ends a step more than `MISS` (1 px) from where it was sent, `u` waits until it arrives (`bugs/descending-from-the-helix-head-runs-in-place-on-the-gallery-then-drops-a-turn`). At the head the hand side walks onto the gallery, held or fresh; Up holds. Descending past the foot, or the other side at the foot, walks onto the floor. While `held` (a hit, a death) the feet stay still. Leaving moves the feet onto the floor or gallery (down off the bottom step at the foot) and calls `apply_floor_snap()`. The resolver's `run` follows `is_stair_moving()`, not velocity, which is zero between risers.
- **Player** judges. `MotionState.STAIR` above `KNOCKBACK`; boarding needs the floor and nothing else holding him and drops the buffers; while riding every buffered press is dropped each step (jump, roll, attack, doors, benches, the Memorina); a hit holds the ride still. `Player.teleport` releases the climb and the rider (the respawn goes through it). A death holds the corpse on its tread; the world swap frees it. `air_axis()` and `look_axis()` are 0 while riding; the camera frames the feet plus `frame_bias()`, the steady rise. The resolver plays `run` while the stair moves him and `idle` while it holds him.
- **Validation** (`HelixStair.check`, run on every map by `room_files_test`): the shape is sound and `hand` ±1; floor under the foot and gallery under the head on both sides of the axis; Ivo's capsule meets no solid cell on the way up the column (one-ways pass, 1 px graze); 48 px of gallery on the hand side of the head; on every row from the floor to the gallery the shell's inner faces stand at the silhouette ±2 px.
- **Reach audit.** The legend's STAIR role: `ReachWorldLoader` asks the stair for `reach_ends(cell)` (the floor cell on the other side of the foot, the gallery cell on the hand side of the head) and `ReachAudit` joins their surfaces both ways in every tier.

## The bell tower

`village_bell_tower`, 1x4 screens (640 x 1536) at (9600, 12000) in `home_village`, rebuilt slim in void (`architecture/room-void-outside-the-shell`): void cols 0-4 and 15-19 and rows 46-47, stone cols 5 and 14 (inner faces x 192 and 448), roof row 0, floor row 45. The door at col 6, row 44; `@` at col 10, row 44 (axis x 320, base y 1440); the gallery is row 10, cols 6-13 of one-way planks (top y 320); the double-jump alcove ledge is row 4, cols 12-13, 6 rows above the gallery (design 04 §3.1). Backdrop `interior_stone` (the view covers it).

## Follow-ups

- The user approves a still at φ 0, a quarter turn and the head before tuning (the revision's art contract); the fallback is precomputed step-phase frames for the stair alone.
- `lighthouse_interior` (design 04 §3.3): a second `HelixLook` in stone and iron, with two flights around the mentor room, and the void.
- The taller `bell_tower_facade` in the square.

## Tests

`tests/scenes/world/interactables/helix_stair/` (`helix_projection_test`, `helix_faces_test`, `helix_math_test`, `helix_steer_test`, `helix_stair_test`, `helix_view_test`), `tests/resources/world/helix/helix_stair_shape_test.gd`, `tests/scenes/characters/components/helix_rider_component_test.gd`, `tests/scenes/characters/ivo/player_helix_test.gd`, `room_files_test.test_every_helix_stair_rides_clear`, `reach_audit_test` (the STAIR edge), `room_reach_test`. Playtest timeline: `tools/playtest/scripts/bell_tower_helix_climb.json`.
