---
id: architecture/character-controller-input-split
type: architecture
title: CharacterController/PlayerInput split — continuous input is a property, discrete input is a signal
status: active
tags: [character, input, composition, template-method, signals]
related: [architecture/animation-driver-resolver-pattern]
created: 2026-09-20
updated: 2026-09-20
source_files:
  - scenes/characters/character.gd
  - scenes/characters/character_controller.gd
  - scenes/characters/ivo/player_input.gd
---

## Summary

`Character` never reads `Input` directly. A `CharacterController` node supplies movement
intent; `PlayerInput` is the player's concrete controller, and enemy AI will be another.
The controller exposes continuous state (movement axis, held modifiers) as a typed
read-only property sampled on read, and emits signals for discrete events (jump pressed,
dash, attack).

## Details

- `Character extends CharacterBody2D` (`scenes/characters/character.gd`) is the shared
  substrate: facing, gravity, health/hurtbox wiring, knockback, and `_physics_process` as
  a template method (`_process_motion` → `move_and_slide()` → `_after_move`).
- `Character.direction` uses the `get = _get_direction` getter form rather than an inline
  getter, specifically so a subclass can override `_get_direction`.
- `CharacterController extends Node` supplies intent; `Character` is agnostic to where
  that intent comes from — it could be `PlayerInput` today, an AI controller tomorrow.

## Why

This is what lets enemy AI reuse the entire `Character` substrate (gravity, knockback,
health) without any of it knowing or caring that its "input" comes from a state machine
instead of a keyboard. It's the Strategy pattern applied to intent.

## Gotchas / pitfalls

- **Do not cache a continuous property in `_physics_process`.** See
  [gotchas/physics-parent-before-children-one-frame-lag](../gotchas/physics-parent-before-children-one-frame-lag.md) —
  Godot processes parents before children, so a cached read is one frame stale relative to
  a live poll.
- A past-tense "changed" signal carrying a *level* value (e.g. `direction_changed(dir)`)
  is the anti-pattern this split exists to avoid: it fires every frame, forces every
  consumer to keep a shadow copy, and couples downstream logic to emission cadence. If
  you're about to add a signal for something continuous, make it a property instead.
