---
id: architecture/animation-driver-resolver-pattern
type: architecture
title: Code decides, the AnimationTree renders — AnimationDriver + per-character AnimationResolver
status: active
tags: [animation, resolver, priority-chain, strategy]
related: [architecture/character-controller-input-split, gotchas/animationtree-reset-track-overwrites-script-writes]
created: 2026-09-20
updated: 2026-09-20
source_files:
  - scenes/characters/ivo/player_animation_resolver.gd
  - scenes/characters/enemies/brute_shadow/brute_shadow_animation_resolver.gd
---

## Summary

Each character's `AnimationTree` is a flat set of clips with no transitions and no
`advance_expression` strings. `AnimationDriver` (generic playback) and a concrete
`AnimationResolver` subclass sit beside it. Every frame, `Character._physics_process`
calls `resolve()` on the resolver and hands the result to the driver.

## Details

- `resolve()` is an ordered priority chain; its order is the only tie-break anywhere in
  the animation system.
- The resolver owns the character's entire clip vocabulary as `const` `StringName`s at
  its top — nothing else names a clip, not the character script, not `Character`.
- Gameplay that needs to know an animation finished asks the resolver in gameplay terms
  (`is_death_finished()`, `is_spawn_finished()`), never in clip terms.
- Intro/one-shot clips are held via `AnimationDriver.holding()`/`sequence()`; a clip that
  must restart itself (a pogo chain, a second hit mid-flinch) calls
  `AnimationDriver.request_replay()`.
- Events arriving from the physics flush (hits, area triggers) land after the frame's
  `_physics_process`, so pulses for them (`Character.just_hit()`) are cleared after
  resolve, not before.

## Why

Adding an animation becomes a three-step, compiler-checked change: author the clip, add
its tree node, add a const + one priority-chain line. A typo in a `const` name fails to
compile; a typo in a loose `&"..."` literal silently plays nothing — this is why no clip
name may ever be a loose string literal.

## Gotchas / pitfalls

- Never add a transition to a state machine — the whole point is that Godot's built-in
  transition graph is unused; all branching lives in `resolve()`.
- A `RESET` track on any property is a trap for anyone who writes that property from
  script — see [gotchas/animationtree-reset-track-overwrites-script-writes](../gotchas/animationtree-reset-track-overwrites-script-writes.md).
- Durations that must equal a clip's length (roll time vs. roll clip, attack phase vs.
  swing clip) are asserted at startup in debug builds — retune either side and the assert
  says which pair drifted. Don't skip re-running with assertions on after retuning timing.
