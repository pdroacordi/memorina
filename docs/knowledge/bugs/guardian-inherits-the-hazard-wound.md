---
id: bugs/guardian-inherits-the-hazard-wound
type: bug
title: A guardian inherits Character's new hazard default, so water wounds and flinches a body whose hits are phase-gated and never wound
status: fixed
severity: low
tags: [hazard, guardian, character, liskov, fragile-base-class, water, combat]
related: [architecture/hazard-respawn-on-safe-ground, architecture/guardian-fight-phase-machine, bugs/roll-iframes-hide-the-water-so-the-pool-floor-becomes-safe-ground]
created: 2026-09-23
updated: 2026-09-23
source_files:
  - scenes/characters/character.gd
  - scenes/characters/guardians/guardian.gd
  - scenes/combat/hazard/hazard_zone.gd
  - scenes/world/environment/water/water_pool.tscn
---

## Summary

84ada2e added a default hazard response to the base class (`Character._on_hazard_touched`):
take `hazard.damage` through `Health`, flash `hurt_flash_color`, and set `_just_hit`.
`Guardian` overrides the hit path (`_on_hit_received`) so that hits never touch `Health`
and only count outside the fight's gate. It does not override the new hazard path. So a
guardian whose hurtbox enters a `HazardZone` is wounded and flinches in any phase. That
breaks the guardian's documented contract ("A guardian is never killed... its Health is
inert", guardian.gd:14-15).

## Symptom

Found in design review of b0fbbd4..7cfe1fe. Reasoned from the code, not reproduced. No
arena has water today, so nothing can trigger it yet.

The path is fully wired. The pool's `Hazard` monitors layer 17
(`collision_mask = 66048`, water_pool.tscn). Both guardians' hurtboxes sit on layer 17
(`collision_layer = 65536`: bloom_guardian.tscn:747, frost_guardian.tscn:745).
`WaterVolume`'s docstring expects guardians in pools: "a guardian landing in a pool
disturbs it exactly as Ivo does". If a guardian lands in water (a lucidity leap, a pounce
or a charge over a pool), it will:

- Lose 1 of its 999 `max_hp` per entry. The HP is inert, but the design says a guardian
  is never wounded.
- Flash `hurt_flash_color` instead of its own `hit_flash_color`, and pulse `_just_hit` in
  LUCIDITY, RELAPSE or RESTORED. In those phases `Guardian._on_hit_received` refuses a
  flinch (guardian.gd:268-271).

## Root cause

Fragile base class. character.gd:118-123 gives every subclass new default behaviour.
The one subclass that had already redefined what being hurt means (`Guardian`) was not
revisited. The hazard path copies the damage/flash/pulse lines of `_on_hit_received`
(character.gd:106-113) instead of going through a hook that `Guardian` already controls.

## Fix

Not fixed. Two options:

- Minimal: `Guardian` overrides `_on_hazard_touched` with an explicit no-op, or with
  whatever a guardian does in water, which is a design call. Add a comment that the fight
  owns its feedback.
- Structural: route the shared "wound" through one hook, e.g. `Character._wound(damage)`,
  called by both `_on_hit_received` and `_on_hazard_touched`. `Guardian` then overrides
  that single point. A future third damage source cannot bypass it the same way.

## Prevention

Any new default behaviour added to `Character` should be checked against every override
of its sibling handlers (`grep "func _on_hit_received" scenes/characters`). A subclass
that redefines one way of being hurt almost certainly needs to redefine the others too.

## Resolution (2026-09-23)

`Guardian.receive_hazard()` is overridden to do nothing: its health is inert, and water never wounds it.
