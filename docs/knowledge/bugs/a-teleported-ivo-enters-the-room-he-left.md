---
id: bugs/a-teleported-ivo-enters-the-room-he-left
type: bug
title: After arriving on a bench outside BloomHollow, the camera fades into BloomHollow, the room of Ivo's authored start
status: fixed
severity: medium
tags: [arrival, bench, room, physics, teleport, death, title]
related: [gotchas/a-teleported-kinematic-body-overlaps-from-its-old-place-for-one-step, systems/life-benches-death, systems/rooms, architecture/the-life-loop-rewinds-by-reloading, architecture/save-slots-and-the-boot-swap, gotchas/first-process-frame-can-precede-the-first-deferred-flush]
created: 2026-10-02
updated: 2026-10-06
source_files:
  - scenes/world/game.gd
  - scenes/characters/character.gd
  - scenes/characters/components/sit_component.gd
  - scenes/characters/ivo/player.gd
---

## Summary

`Game._arrive()` seats Ivo on the saved bench, and on the next physics step the room containing his
authored start (BloomHollow) reports `body_entered`. `Game` fades into that room, so the camera bounds
and the memory field belong to a room he is not in.

## Symptom

Found in the UI-05 windowed check (2026-10-02): Continue on a save at `downtown_bench` showed
BloomHollow's pillar instead of Ivo on the bench. Ivo's node was at the seat (-1104, 0) throughout.

The same thing happened after a death: HEAD's `_reload_world`, untouched by UI-05, logged
`room=BloomHollow` after respawning on the Downtown bench. It happens on every arrival that builds the
game inside a deferred flush: a death rebuild, Boot, and the title's Continue.

## Root cause

- Ivo's authored start in `game.tscn` is (3277, -69), inside BloomHollow (x 2544.5..4464.5).
- At tree entry his body's first transform is applied on the physics server at once.
- `_arrive` then disables him (removed from the space), seats him on the bench (`game.gd:113`) and
  re-enables him (`game.gd:119`).
- A CharacterBody2D is a kinematic body. The server's transform for a kinematic body moves only on a
  physics step: `body_set_state(TRANSFORM)` stores the target and the step applies it.
- So Ivo re-entered the space at the authored start for one step. Measured with
  `PhysicsServer2D.body_get_state(rid, BODY_STATE_TRANSFORM)`:
  - `physics=7 node=(-1104, 0) server=(3277, -69)`;
  - BloomHollow's `body_entered` fired at physics 8.
- `Game._on_player_entered_room` trusted the overlap.

Things that did not fix it, both measured:
- `await get_tree().physics_frame` before re-enabling: the step runs while Ivo is out of the space, so
  the stored target is never applied.
- `force_update_transform()` before re-enabling.

The engine contract stands: every teleport of a kinematic body leaves the server one step behind the
node.

## Fix

Fixed at the source on 2026-10-06, replacing the first fix: a consumer guard, `RoomEntry.is_stale` plus `Player.body_bounds()`, which is removed.

`Character.teleport(point)` (static `Character.teleport_body(body, point)`) writes the position and puts the physics server there in the same call. It runs the measured sequence `body_set_mode(STATIC)`, `body_set_state(TRANSFORM)`, `body_set_mode(KINEMATIC)` (`gotchas/a-teleported-kinematic-body-overlaps-from-its-old-place-for-one-step`). It is used by:
- `SitComponent.sit` (arrival and resting);
- `Player.respawn`;
- `DebugTrials`;
- the playtest runner's `player_position`.

Evidence:
- `tests/scenes/characters/character_teleport_test.gd` pins the engine: a plain write still gives `enter`, `exit`; `teleport_body` gives none; afterwards the body lands and a walk-in is a real `enter`.
- In game, 5 title Continues logged `entries=["Downtown@143"]`, and 5 deaths logged `["Downtown@3"]` before and `["Downtown@300"]` after. All settled in Downtown with no BloomHollow entry at all.
- Before the fix, every run logged `BloomHollow` one step before `Downtown`.

## Revision (2026-10-02, review)

The root cause stands; the fix is scoped to `Room` only. Any other Area2D that detects Ivo's body
at the place he left gets the same stale step. A source-level fix was measured in a scratch
project (`gotchas/a-teleported-kinematic-body-overlaps-from-its-old-place-for-one-step`):
- `body_set_state(TRANSFORM)`, `remove_child`/`add_child`, and the same-mode `body_set_mode`
  still give the stale `enter`/`exit`.
- `body_set_mode(STATIC)`, `body_set_state(TRANSFORM)`, `body_set_mode(KINEMATIC)` after the move
  gives none, and floor detection and later genuine entries are unchanged. This relies on
  GodotPhysics2D internals (`first_time_kinematic`).
- The test box in `room_entry_test.gd` (16x42) is not Ivo's body: the capsule is 22x54 at
  offset (-1, -27). The verdicts do not change.

## Revision (2026-10-06)

The reviewer's source fix replaced the consumer guard (see Fix). Every Area2D that detects Ivo's body now sees him where the node is, not only `Room`.
