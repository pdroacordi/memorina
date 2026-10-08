---
id: gotchas/disabling-a-body-inside-its-own-physics-step-errors-its-move
type: gotcha
title: Setting a CharacterBody2D to PROCESS_MODE_DISABLED inside its own _physics_process removes it from the space at once; the move_and_slide that follows errors and clears is_on_floor
status: active
tags: [physics, process-mode, disable-mode, character-body, move-and-slide, signal, deferred, template-method]
related: [bugs/taking-a-door-disables-ivo-inside-his-own-physics-step, gotchas/body-state-cannot-change-in-the-physics-flush, gotchas/a-teleported-kinematic-body-overlaps-from-its-old-place-for-one-step]
created: 2026-10-08
updated: 2026-10-08
source_files:
  - scenes/characters/character.gd
  - scenes/world/game.gd
---

## Summary

With the default `disable_mode` (REMOVE), `process_mode = PROCESS_MODE_DISABLED` takes a
CollisionObject2D out of its physics space synchronously. When that happens partway through
the body's own `_physics_process`, for example from a handler of a signal the body emitted
there, the `move_and_slide()` later in the same call errors and leaves `is_on_floor()` false.

## Details

Measured on 4.7.2, headless, in a scratch project (2026-10-08, WORLD-09 review). A
CharacterBody2D stood on a StaticBody2D floor. On its 5th step its `_physics_process` set
`process_mode = PROCESS_MODE_DISABLED` and then called `move_and_slide()`:

```
ERROR: Parameter "body->get_space()" is null.
   at: body_test_motion (modules/godot_physics_2d/godot_physics_server_2d.cpp:996)
after move_and_slide: on_floor=false
```

- The `callback_lock` guard ("Disabling a CollisionObject node during a physics callback is not
  allowed") covers only the physics flush (`body_entered` and the like), not `_physics_process`.
  So no warning comes first.
- `move_and_slide()` resets the floor state before it tests motion, so `is_on_floor()`,
  `is_on_wall()` and `get_floor_normal()` read as airborne until the body moves again after
  re-enabling.
- In this project, `Character._physics_process` is a template method: `_process_motion` →
  `move_and_slide()` → `_after_move`. Any signal emitted from `_process_motion` whose handler
  disables the character hits this.

The same probe confirmed that a child left at `PROCESS_MODE_INHERIT` receives
`NOTIFICATION_PAUSED` + `NOTIFICATION_DISABLED` when its parent is disabled, and
`NOTIFICATION_UNPAUSED` + `NOTIFICATION_ENABLED` when the parent is re-enabled. So
`PlayerInput.resync` runs twice on each re-enable of Ivo.

## Gotchas / pitfalls

- Disable from outside the step: `set_deferred(&"process_mode", ...)`, or emit the signal
  deferred. The message queue is flushed at the end of each physics frame.
- `_arrive` and the walk-in transition are safe: they disable Ivo from `Game._ready` and from
  a Room's `body_entered`, never from inside his step.
- A suite that drives the body without the handler that disables it (for example
  `player_door_test` without `Game`) never sees the error.
