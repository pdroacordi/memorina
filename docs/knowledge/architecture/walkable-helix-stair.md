---
id: architecture/walkable-helix-stair
type: architecture
title: Walkable helix stair - Ivo rides a parametric spiral; a ForegroundPass twin of the near runs puts him behind them
status: accepted
tags: [helix, stair, interior, bell-tower, lighthouse, movement-mode, depth, canvas-pass, camera]
related: [systems/roots-and-climbing, architecture/roots-join-earth-to-earth, systems/foreground, architecture/secret-false-walls, systems/rooms, systems/world, systems/greyhush, systems/animation, systems/backdrops, systems/art-pipeline, architecture/room-reachability-audit, gotchas/animationtree-reset-track-overwrites-script-writes, gotchas/physics-parent-before-children-one-frame-lag]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/characters/ivo/player.gd
  - scenes/characters/components/climb_component.gd
  - scenes/world/camera.gd
  - scenes/world/memory/canvas_pass.gd
  - scenes/world/rooms/home_village/contents/village_bell_tower.room
---

# Walkable helix stair

WORLD-26. User, 2026-10-10: "the player goes spinning and it almost looks like an optical illusion". Choice: "Walkable helix (Recommended)". `lighthouse_interior` (design 04 §3.3) reuses it.

## Context

Ivo walks a spiral: in front of the near run, behind the far run (smaller, darker), turning at the sides. Characters draw only in the creature pass, over the whole world composite, so nothing in the root canvas can cover him (`systems/foreground`).

## Options considered

- **Movement.** One-way slopes per run with normal physics: near and far cross on screen, so the body takes the wrong branch at each crossing. Flat switchback ledges under decorative art: no illusion. **A parametric ride** (chosen), as climbing follows a `Climbable`.
- **Occlusion.** Moving Ivo between canvases breaks the creature pass; a depth shader has no precedent. **A `ForegroundPass` twin of the near runs** (chosen, the `SecretWall` pattern).
- **Art.** A procedural shader draws weak pixel art. **Static half-turn sprites stacked by pitch** (chosen): a rising camera makes a static helix seem to turn, as in the reference.

## Decision

**Path** (pure `HelixMath`, `scenes/world/interactables/helix_stair/`). Progress `u` in 0..turns·TAU, `a = u - PI/2`: feet = (cx + hand·R·sin a, base - pitch·u/TAU - tilt·cos a); depth = cos a. `tilt` (the view's ellipse, near drawn higher) lets the near run cross in front of the far one. `turns` is a multiple of 0.5, so both ends sit at a side with depth and tilt 0, on cell tops. Angular speed is constant, `speed / sqrt(R² + (pitch/TAU)²)`, so screen speed slows at the sides and the turn reads as rotation.

**Input** (pure `HelixSteer`). Up ascends, Down descends; left/right move along the run in its screen direction, latched through a turn while held (hold one direction, spin up); vertical wins a diagonal at 0.5. `Player` passes `Vector2(move_axis(), look_direction)`; only `PlayerInput` reads input.

**Ownership.** `HelixStair` (root `Area2D`, legend `@`) owns its art, two `HelixEnd` zones on the climbable layer and `set_rider_depth()` / `clear_rider()`. `HelixRiderComponent` (generic, `components/`, ungated) holds it, finding ends through `ClimbSensor` (`ClimbComponent` ignores non-`Climbable` areas). `Player` judges: `MotionState.STAIR` above `KNOCKBACK`; boards in an end zone on a fresh press into the stair or Up/Down, with `ClimbComponent`'s regrab delay; while riding, jump, roll, attack, doors and the Memorina are refused and their buffers dropped, and a hit does not unseat him. The rider sets `velocity = (feet(u) - position) / delta`, so `move_and_slide` keeps collision (a test proves the swept body is air). Past the foot he steps onto the floor; at the head he waits for the outward press, so a held latch never walks him off the landing. `arrive_at`, `sit`, `respawn` and death release the rider; `_landing.check_landing(on_floor or riding)`.

**Depth.** Far runs: world art, z -15. Near runs: a world copy (z 5) and a `ForegroundPass` twin (`CanvasPass.join_layer`, z -1), hidden while the rider's depth > 0.15, shown again below 0.05; off the stair Ivo stands in the axis plane, behind the near runs. The twin is greyed by the foreground composite like the world copy. Facing follows screen x velocity with a dead zone |cos a| < 0.15: one flip, in profile. `DepthLook` (generic component) receives `near` 0..1 from `Player` (like `AirflowBody.exposure`) and, in its own step after the parent's, writes the Sprite2D's `scale` (feet kept) and `self_modulate` (`flash()` owns `modulate`); no RESET track keys either today. The shade is a value multiply in Ivo's own hues, independent of memory, never touching his clocks; the greyhush desaturates and stops time.

**Camera.** One tall room, no seams on the climb. `air_axis()` is 0 while riding, so neither the air lead nor the fall lead runs. A new optional intent `frame_bias()` (+tilt·cos a, read by `has_method` like `air_axis`) frames the axis height: the frame rises steadily and the helix seems to turn; framing the feet would bob the stair ±tilt.

**Data.** `HelixStairShape` Resource (`resources/world/helix/`): `radius`, `pitch`, `turns`, `tilt`, `speed_scale`, `far_scale`, `far_shade`, `near_art`, `far_art` (art drawn for these numbers: one contract). In the `.room`, `@` on the bottom floor, its cell's bottom-left corner the axis base (an even shaft centres on a grid line); params `shape` (a `.tres` path, like a door's `requires`) and `hand` (1: near run climbs right). A static `HelixStair.check(cell, params, map)` feeds `room_files_test` (ends on floor tops, a landing at the head, swept body clear); for the reach audit it is a two-way edge foot to head. Landings are side ledges; the stair never crosses a floor; the lighthouse's mentor room makes two flights. The bell tower becomes 1x4 in `gen_world_shells.py` (from y 12000 down), its `.room` rewritten by hand. Start at R 128, pitch 320, tilt 56, 3.5 turns: about 20 s at 192 px/s. The double-jump alcove stays above the top landing (design 04 §3.1).

**Art** (contracts in `tools/art/prompts/`, then a style board for approval): `helix_stair_wood` (near: underside and stringer; far: treads, darker; one band, 2x); `bell_tower_shaft`, a seamless vertical wall with warm light slits (`cut_wall.py`, a `BackdropSet` with REPEAT fills); `bell_tower_facade` redrawn taller, rising out of `village_square`'s top edge like the lighthouse base, doorway still 64 px. The user's reference images are never uploaded; contracts describe them in words. Placeholders are baked from `HelixMath`, so tuning precedes art.

**Tests** (mirroring the source path): ends at sides with zero tilt, head height, constant 3D speed, screen x speed 0 at the sides, one facing flip per half-turn, latch held through a turn and reset on release, cover hysteresis, `feet + frame_bias` linear in u. Playtest: hold right from the door to the top.

## Consequences

No user-facing text, so nothing for `tr()`. The stair art is bound to its numbers: retuning means re-cutting it. Cut first if costly: the far scale (non-integer scaling of 2x art may shimmer; keep the shade), front and back turn clips, a stair through a ceiling.

## Answers (2026-10-11)

1. Jump on the stair: "Nothing (Recommended)" (user).
2. The Memorina on a step: refused (orchestrator's call, the plan's proposal; the user was not asked).
3. Height: "4 screens (Recommended)" (user).
4. If the far scale shimmers: darker only (orchestrator's call, the plan's fallback).
5. The lighthouse stair: "Stone and iron (Recommended)" (user).
