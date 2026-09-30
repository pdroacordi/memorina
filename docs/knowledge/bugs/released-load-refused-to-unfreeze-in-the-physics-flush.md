---
id: bugs/released-load-refused-to-unfreeze-in-the-physics-flush
type: bug
title: Soltar reached a hanging load but it never fell - unfreezing inside the physics flush is refused
status: active
tags: [releasable, rigidbody, freeze, physics-flush, song-receiver, call-deferred]
related: [gotchas/body-state-cannot-change-in-the-physics-flush]
created: 2026-09-30
updated: 2026-09-30
source_files:
  - scenes/world/interactables/releasable/releasable.gd
  - scenes/world/interactables/hanging_load/hanging_load.gd
---

## Summary

A pulse reaches a `SongReceiver` through `area_entered`, inside the physics flush.
`HangingLoad._on_released` set `freeze = false` there; Godot refused ("Can't change this
state while flushing queries") and the load stayed on its rope. `Releasable` now emits
`released` / `restored` with `call_deferred`.

## Also found

The load's return tween was not stored: a second pulse during the fade let it go and the
old tween hung it back up under a lit pulse (Codex review). It is now kept and killed on
release; `LeafCover` got the same one-fade-at-a-time rule.
