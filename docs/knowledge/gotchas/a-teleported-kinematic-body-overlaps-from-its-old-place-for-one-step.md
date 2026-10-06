---
id: gotchas/a-teleported-kinematic-body-overlaps-from-its-old-place-for-one-step
type: gotcha
title: A teleported CharacterBody2D overlaps Area2Ds from its old place for one physics step; only a server mode toggle applies the move at once
status: active
tags: [physics, kinematic, character-body, teleport, area2d, body-entered, transform]
related: [bugs/a-teleported-ivo-enters-the-room-he-left, gotchas/sync-to-physics-lands-a-move-next-step, systems/rooms, systems/life-benches-death]
created: 2026-10-02
updated: 2026-10-06
source_files:
  - scenes/characters/character.gd
  - scenes/characters/components/sit_component.gd
  - scenes/characters/ivo/player.gd
  - scenes/world/game.gd
---

## Summary

A `CharacterBody2D` is a KINEMATIC body. Writing its `global_position` only stores a target on
the physics server. The next step runs the broadphase and the Area2D pairs at the old transform,
then moves the body. Every body-detecting Area2D at the old place reports `body_entered` (and
`body_exited` one step later), even though the node never stood there after the write.

## Details

Measured on 4.7.2, headless, in a scratch project (2026-10-02 review of UI-05). Setup: a 200x200
Area2D at the origin; a CharacterBody2D added at the origin and disabled in the same frame
(`PROCESS_MODE_DISABLED`, so it leaves the space before any step); a few frames later it is moved
to (1000, 0) and re-enabled.

| What was done after the move | Server transform at re-enable | Area events |
|---|---|---|
| nothing | (0, 0) | `enter`, `exit` one step later |
| `PhysicsServer2D.body_set_state(rid, BODY_STATE_TRANSFORM, global_transform)` | (0, 0) | `enter`, `exit` |
| `remove_child` + `add_child` of the body | (0, 0) | `enter`, `exit` |
| two `await physics_frame` before re-enabling | (0, 0) | `enter`, `exit` |
| `disable_mode = KEEP_ACTIVE` (body stays in the space) | (0, 0) | `enter` (genuine, at the start), `exit` 3 steps later |
| `body_set_mode(rid, KINEMATIC)` then `body_set_state(TRANSFORM)` | (0, 0) | `enter`, `exit` (same mode is a no-op) |
| `body_set_mode(rid, STATIC)`, `body_set_state(rid, TRANSFORM, global_transform)`, `body_set_mode(rid, KINEMATIC)` | (1000, 0) | none |

Why: in GodotPhysics2D, `set_state(TRANSFORM)` on a kinematic body sets `new_transform` and applies
it immediately only while `first_time_kinematic` is set, which happens when the mode changes to
KINEMATIC. `GodotStep2D::step` updates the broadphase and the area pairs before
`integrate_velocities` applies `new_transform`. A body re-added to the space (`_apply_enabled`)
re-enters at its last applied transform.

The same probe, with the body enabled and teleported away from inside the area, then dropped onto a
floor and walked back in: the mode toggle made `exit` arrive one step earlier (next step instead of
two), and `is_on_floor()`, `move_and_slide()` and the later genuine `enter` all behaved as without
it.

## Gotchas / pitfalls

- Any Area2D that detects Ivo's body (rooms, hazards per `systems/water`, wind zones) sees one
  stale step after every teleport: `SitComponent` (`sit_component.gd:32`, also the arrival seat),
  `Player.respawn()` (`player.gd:1004`).
- `body_set_state(TRANSFORM)` and `force_update_transform()` look like fixes and are not.
- The mode toggle relies on GodotPhysics2D internals (`first_time_kinematic`), not on documented
  API. If it is adopted as a `Character.teleport()`, pin it with a headless physics test like the
  probe above: physics steps and area events run headless.
- In normal motion the node is one step ahead of the server, so an overlap reported now is where
  the body was before the last `move_and_slide()`.
- **Adopted 2026-10-06** as `Character.teleport(point)` / `Character.teleport_body(body, point)` (`scenes/characters/character.gd`). Every non-motion move of a character goes through it: the seat, the respawn, `DebugTrials`, the runner. `tests/scenes/characters/character_teleport_test.gd` pins both the plain-write stale step (a control: if it ever fails, the engine changed) and the fix.
