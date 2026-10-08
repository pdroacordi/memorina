---
id: bugs/taking-a-door-disables-ivo-inside-his-own-physics-step
type: bug
title: Taking a door disables Ivo inside his own physics step, so move_and_slide runs on a body with no space and logs two engine errors per trip
status: resolved
severity: low
tags: [doors, physics, process-mode, signal, deferred, character, move-and-slide, world-09]
related: [architecture/doors-and-interiors, playtests/2026-10-08-doors-and-interiors, systems/weight-presence-release, systems/life-benches-death]
created: 2026-10-08
updated: 2026-10-08
source_files:
  - scenes/characters/ivo/player.gd
  - scenes/characters/character.gd
  - scenes/world/game.gd
---

## Summary

`Player._try_door` emits `door_entered` synchronously from `_process_motion`. `Game._on_player_entered_door`
sets Ivo to `PROCESS_MODE_DISABLED` before its first await, which removes the body from the physics
space at once. `Character._physics_process` then continues to `move_and_slide()` on a spaceless body.

## Symptom

Found by the 2026-10-08 doors playtest (WORLD-09, uncommitted on ce07360). Every trip through a door
prints, once per press, in every run:

```
ERROR: Parameter "body->get_space()" is null.
   at: body_test_motion (modules/godot_physics_2d/godot_physics_server_2d.cpp:996)
   GDScript backtrace (most recent call first):
       [0] _physics_process (res://scenes/characters/character.gd:57)
```

The error appears twice per trip (two `body_test_motion` calls in one `move_and_slide`). Reproduced 4/4
runs: `tools/playtest/scripts/door_front_round_trip.json` (two trips, four errors),
`door_hatch_walk_and_air.json`, `door_hatch_unsealed.json`. A knock at a sealed door prints nothing:
it emits no signal and nothing is disabled. No visible effect: the fade and arrival are correct.

## Root cause

- `character.gd:54-60`: `_process_motion(delta)` → `move_and_slide()` in one call.
- `player.gd` `_try_door` (called from `_process_motion`) → `door_entered.emit(door)`.
- `game.gd` `_on_player_entered_door` → `_player.process_mode = Node.PROCESS_MODE_DISABLED` runs
  synchronously inside the emit. `CollisionObject2D.disable_mode` defaults to REMOVE, so the
  DISABLED notification takes the body out of its space right there.
- Control returns to `Character._physics_process`, which calls `move_and_slide()` on that body.

`_arrive` and the hazard beat do not hit it: `_arrive` disables Ivo outside his step, and the hazard
beat awaits a timer before touching him.

## Fix

Fixed 2026-10-08 (WORLD-09): `Game._on_player_entered_door` disables Ivo with `set_deferred`, and
`Player._try_door` calls `_drop_buffers()` before it emits, so no draw, jump, roll or attack
pressed in the same frame acts on the way out. The options weighed were:
- emit `door_entered` deferred from `Player` (the same rule as release signals: "emitted deferred"), or
- set `_player.process_mode` with `set_deferred` in `Game._on_player_entered_door`.

Either way the press frame finishes its move first. `_is_transitioning` is already set synchronously,
so a second press in that frame is still refused.

## Prevention

A signal that a physics step emits must not let its handler disable or free the emitter synchronously.
`player_door_test` drives `_try_door` without `Game`, so no suite sees this. A `Game`-level test that
takes a door and asserts no engine error would catch it.

## Revision (2026-10-08, review)

The root cause stands. The effect is wider than the two errors. The probe in `gotchas/disabling-a-body-inside-its-own-physics-step-errors-its-move` measured it: the failed `move_and_slide()` also clears `is_on_floor()`.

What follows from the code (not measured in game; the runner's `floor=` and `state=` columns at the arrival frame show it):
- `_after_move` → `LandingComponent.check_landing(false)` stores `_was_on_floor = false` for the whole trip, and `can_open_map()` reads false.
- On the first step after the re-enable, `_process_motion` reads `is_on_floor()` false and runs the AIR state. The move then lands him, so `just_landed()` is true and `PlayerAnimationResolver` resolves `LAND`: Ivo plays a landing at the door he walked out of.
- Unrelated to the disable: `_try_door` returns into the rest of `_process_motion`, so `_try_memorina`, `_try_jump`, `_try_roll` and `_try_attack` still act in the departure step. A draw or jump pressed in the same frame as Up has already fired by then, and `arrive_at`'s `_drop_buffers()` cannot undo it. With the draw, he arrives holding the Memorina.

Fix, in addition to the deferral above:
- `_try_door` calls `_drop_buffers()` when it emits `door_entered`, so nothing else acts in the departure step.
- `set_deferred` the process mode, so the departure step's move runs on a body that is still in its space.
