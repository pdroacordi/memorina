---
id: bugs/a-released-load-presses-ivo-into-the-floor
type: bug
title: A released hanging load that falls on Ivo presses him into the floor and he stays stuck there
status: fixed
severity: high
tags: [hanging-load, rigidbody, characterbody, collision-mask, soft-lock, soltar, release]
related: [playtests/2026-10-07-empty-house, systems/weight-presence-release, bugs/released-load-refused-to-unfreeze-in-the-physics-flush]
created: 2026-10-07
updated: 2026-10-07
source_files:
  - scenes/world/interactables/hanging_load/hanging_load.tscn
  - scenes/world/interactables/hanging_load/hanging_load.gd
  - scenes/characters/ivo/ivo.tscn
---

## Symptom

Ivo stands under a hanging cocoon (the empty house's `house_load`, col 32) and plays Soltar.
The cocoon falls onto the plate he is standing on. Within 0.3 s Ivo's position drops from
y 6000 (floor top) to y 6054.2, so he is 54 px inside the ground with only his head above
it. He stays there in `fall_idle` at y velocity 1000 (terminal fall speed) with hp 3. Moving
left or right, and jumping, does not free him. He is still stuck at t 31, after Soltar's
pulse has ended and the cocoon has gone back to its rope (~t 27). The only ways out are
F10 (debug) or quitting. This is a soft-lock.

Repro: `tools/playtest/scripts/song_empty_house_under_long.json` (Ivo at [13200, 5982],
`known_songs` [4], Soltar at t 1.5). Frames: `playtests/screenshots/2026-10-07-empty-house/ivo_pressed_into_the_floor_12.2.png`,
`ivo_still_in_the_floor_31.0.png`.

Played from one cell to the left (x 13160) or the right (x 13260), the cocoon lands
cleanly on the plate and nothing goes wrong.

## Root cause

Likely cause, inferred from the collision setup and not traced in the engine. `HangingLoad`
is on layer 2 with mask 11 (layers 1, 2, 4). It does not collide with Ivo (layer 9, value
256), so it falls through him onto the plate. Ivo's mask 11 does include layer 2 (so he
can stand on a load), so after the load lands `move_and_slide` finds him overlapping it.
The depenetration then pushes him down into the ground tiles, where nothing pushes him back
out. The same `hanging_load.tscn` hangs over plates in the autumn trial at the same
`hang_height` 32, so the bug probably exists there too. That was not run.

## Fix

Fixed 2026-10-07: the load's mask includes the Player layer (`hanging_load.tscn` `collision_mask` 11 -> 267), so a released load lands on Ivo's head and falls on to the plate when he steps out. Verified with `song_empty_house_under_long.json`: Ivo stands on the floor (y 6000) at t 31.

Options that were considered:
- Let the load see Ivo (add layer 9 to its mask), so it rests on his head the way a crate
  would.
- Stop the release while a body is underneath.
- Make the load ignore Ivo for depenetration until it has landed.

## Prevention

A puzzle that hangs a load over a plate invites the player to stand on that plate. Any
falling `RigidBody2D` that Ivo collides with must also collide with Ivo, or must never come
to rest overlapping him.
