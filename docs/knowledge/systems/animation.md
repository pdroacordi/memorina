---
id: systems/animation
type: system
title: Animation: code decides, the AnimationTree renders
status: active
tags: [animation, animation-tree, resolver, driver]
related: [architecture/animation-driver-resolver-pattern, gotchas/animationtree-reset-track-overwrites-script-writes]
created: 2026-10-02
updated: 2026-10-02
source_files:
  - scenes/characters/animation_resolver.gd
  - scenes/characters/character.gd
---

# Animation: code decides, the AnimationTree renders

Moved verbatim from `CLAUDE.md` ("Animation") on 2026-10-02.

**Code decides, the AnimationTree renders.** Each character's `AnimationTree` is a flat set of clips with NO transitions and NO `advance_expression` strings. Two components sit beside it: `AnimationDriver` (generic playback — starts a clip only when the name changes) and an `AnimationResolver` (one concrete subclass per character: `PlayerAnimationResolver`, `BruteShadowAnimationResolver`). Every frame `Character._physics_process` calls `resolve()` on the resolver and hands the result to the driver. `resolve()` is an ordered priority chain; its order is the only tie-break anywhere.

- **The resolver owns the character's entire clip vocabulary** as `const` StringNames at its top, and nothing else names a clip — not the character script, not `Character`. The resolver reads the character's public predicates (`is_rolling()`, `just_hit()`, ...) and the driver; gameplay that needs to know an animation finished asks the resolver in gameplay terms (`is_death_finished()`, `is_spawn_finished()`). Adding an animation is: author the clip, add its node to the tree, add a const and one line at the right priority in the resolver. Never write a clip name as a loose `&"..."` literal — a typo in a const name fails to compile, a typo in a literal silently plays nothing. Never add a transition to a state machine.

- **Intro / one-shot clips** (`jump_start`, `fall_start`, `wall_landing`, `land`, `air_spin`, `hurt`, `spawn`) are held until they finish via `AnimationDriver.holding()` / `sequence()`; the resolver never needs their durations. An event that must restart the *same* clip (a pogo chain, a second hit mid-flinch) calls `AnimationDriver.request_replay()`. Events that arrive from the physics flush (hits, area triggers) land *after* the frame's `_physics_process`, so a pulse for them (`Character.just_hit()`) is cleared after the resolve, not before.
- **`RESET` is the default pose, and the tree owns every property it declares.** Each clip keys only what it changes (hitbox geometry per swing, i-frames); everything else blends back to `RESET`. Consequence: a script write to any property with a `RESET` track (`Hurtbox:monitorable`, `Hitbox:*`) is silently overwritten every frame. Gate the *decision* in script instead (`Character._on_hit_received` ignores hits while dead), or key it in the clip. `BruteShadow` keeps its tree inactive until spawn for exactly this reason.
- **Durations that must equal a clip's length are asserted at startup** in debug builds (`Character._assert_clip_length`): `roll_time + roll_recovery_time` vs the roll clip, every `AttackPhaseData.duration` vs its swing, `BruteShadowAttackStats.attack_duration` vs `attack`. Retune either side and the assert says which pair drifted.
- When a component takes over logic that previously emitted a signal from `Player`, `Player` must RE-EMIT that signal, because `ivo.tscn`'s connections are declared with `from="."`. This is why `Player` relays `jumped`, `double_jumped` and `hard_landed`.
