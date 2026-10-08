---
id: bugs/a-root-catch-on-a-freed-platform-errors-before-its-validity-check
type: bug
title: RootGrower prunes catches of freed platforms through a typed loop variable, so the is_instance_valid() guard is never reached
status: fixed
severity: low
tags: [enraizar, roots, root-catch, lowering-platform, typing, free, pzl-04]
related: [gotchas/a-typed-loop-variable-fails-on-a-freed-object, systems/roots-and-climbing]
created: 2026-10-08
updated: 2026-10-08
source_files:
  - scenes/world/memory/song_effects/roots/root_grower.gd
---

## Summary

`RootGrower._update_catches` iterates `for body: Object in _catches.keys():` and then tests
`is_instance_valid(body)` to drop the catch of a freed `LoweringPlatform`. A freed key fails the
typed loop variable first, so the function errors on every physics step for the rest of the
pulse and the stale catch is never dropped. Latent: no path frees a platform alone today.

## Symptom

None in play yet. If a seized platform were freed while its `RootGrower` and the grower's
`_room` stay alive, the log would show `Trying to assign invalid previously freed instance.`
at root_grower.gd:137 every physics frame until the pulse ends, and no catch would be advanced
or pruned after that point in the loop. `RootSpanView.advance` runs before `_update_catches` and
is not affected.

## Root cause

root_grower.gd:137 types the loop variable (`body: Object`). GDScript checks a typed slot on
assignment and errors on a freed instance (`gotchas/a-typed-loop-variable-fails-on-a-freed-object`),
so the guard on line 139 cannot run for the case it was written for.

It is latent because platforms are built by the room's `RoomMapNode`, and room eviction frees
the platform and that `RoomMapNode` together. `_room == null` is then true for the freed
node, and `_update_catches` returns at line 124 before the loop. A grower never catches a
platform outside its own room, because `_catch_faces` reads only `_room`'s map.

## Fix

Open. Read the key untyped (`for body in _catches.keys():`), or key `_catches` by
`get_instance_id()` and look the platform up with `instance_from_id()`.

## Prevention

A test that seizes a platform, frees it, and steps the grower once, asserting no error and an
empty `_catches`.

## Resolution

Fixed before commit (2026-10-08): `RootGrower._update_catches` iterates the keys untyped, so `is_instance_valid` runs first.
