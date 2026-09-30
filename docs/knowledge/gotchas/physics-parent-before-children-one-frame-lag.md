---
id: gotchas/physics-parent-before-children-one-frame-lag
type: gotcha
title: Godot processes parents before children — caching continuous input in _physics_process reintroduces a one-frame lag
status: active
tags: [input, physics-process, node-order, footgun]
related: [architecture/character-controller-input-split]
created: 2026-09-20
updated: 2026-09-20
source_files:
  - scenes/characters/character_controller.gd
---

## Summary

Godot's scene tree runs `_physics_process` on a parent before its children in the same
frame. `Character` (the parent, logically) reads intent from a `CharacterController`
(commonly a child node). If the controller's continuous properties were cached once per
`_physics_process` and read back later, the cached value would already be one frame stale
relative to the raw `Input` state by the time the parent consumes it.

## Details

This is exactly why continuous input on a `CharacterController` is exposed as a typed
read-only property that is **sampled on read, never cached** — every read goes straight to
`Input.get_axis(...)` / `Input.is_action_pressed(...)` at the moment it's asked for.

## Prevention

If you see a continuous-input property being written to a local `var` inside
`_physics_process` and read from elsewhere later in the same frame, that's the bug this
entry exists to catch — replace the cached var with a live getter.
