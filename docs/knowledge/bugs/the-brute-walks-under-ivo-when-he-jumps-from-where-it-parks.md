---
id: bugs/the-brute-walks-under-ivo-when-he-jumps-from-where-it-parks
type: bug
title: The brute's stop distance is Euclidean, so a jump from where it parks draws it under Ivo, and a raised Ivo makes it dither
status: fixed
severity: medium
tags: [enemies, brute-shadow, ai, chase, contact, core-09]
related: [systems/guardians, bugs/the-brute-swings-away-from-a-target-already-in-reach, playtests/2026-10-11-core09-retune]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/characters/enemies/brute_shadow/brute_shadow_ai.gd
  - scenes/characters/enemies/enemy_ai.gd
  - resources/characters/enemies/brute_shadow/brute_shadow_attack_stats.tres
  - tests/scenes/characters/enemies/brute_shadow/brute_shadow_ai_test.gd
---

## Summary

`BruteShadowAI._chase_tick` stops at `_within(stop_distance)`, which is a straight-line `distance_to`. Since CORE-09 the brute parks at 48 px, so any jump Ivo makes from there puts him more than 48 px away and the brute walks toward his x. The jump lasts about 1.1 s at 48 px/s, so the brute ends up under him and he lands in its 27 px contact box.

## Symptom

Found in review, not reproduced in play. Expected cases:

- **Jump in place from the parking spot.** Ivo at dx 48 jumps (`jump_height` 144, rise gravity 0.85, so about 1.1 s in the air). The brute is waiting out its cooldown, so it walks about 50 px and passes under him. He lands on the `CollisionHitbox` (radius 18 at x 1, plus his 8) for 1 damage and 400 px/s of knockback. With the old 90 px stop it ended about 40 px short of him.
- **Raised Ivo.** Ivo stands on a ledge 49-90 px above the brute and nearly over it. Every cooldown tick, `EnemyAI._chase_tick` sets `signf(dx)`, so the brute crosses his x, reverses (deceleration 2048 px/s²) and crosses back. `_get_facing_direction` returns `_target_side()` inside `attack_range` with no dead band, so the sprite flips on every crossing. Before CORE-09 this dither started only above 90 px. `GuardianAI` avoids the same dither with `TURN_BAND`.

## Root cause

`brute_shadow_ai.gd:36`: the parking test uses the same Euclidean distance as the attack trigger. Vertical separation therefore counts as "too far", so the brute closes in horizontally whenever Ivo is in the air or above it.

## Fix

- `_chase_tick` parks on `absf(dx) <= stop_distance`. The swing trigger stays Euclidean (`attack_range` 90), so a brute still swings at an Ivo close above it.
- `_target_side()` keeps the side the target was last on while `absf(dx) <= TURN_BAND` (10 px). Facing, and the side a swing is aimed at, no longer flip while Ivo stands nearly overhead.

In game (`core09_brute_jump_in_place.json`), the brute parked at 47.5 px and stayed at 47.5 for Ivo's whole jump in the 96 px caldera tunnel. He landed clear of its contact box and his slash cancelled the swing it started on his landing.

## Prevention

`brute_shadow_ai_test`: a jump from the parking spot (target at 48, -60 and 48, -144 during the cooldown) leaves direction 0; a target on a ledge at dx ±2 and ±6, y -60 neither moves it nor flips its facing, and at -30 it turns without walking.

A "stop at distance" check written as a radius treats a jump as the target moving away. Chase and park checks for ground walkers should use horizontal distance.
