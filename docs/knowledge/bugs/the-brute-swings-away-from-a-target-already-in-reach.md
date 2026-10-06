---
id: bugs/the-brute-swings-away-from-a-target-already-in-reach
type: bug
title: The brute swings away from a target that is already in reach behind it
status: fixed
severity: medium
tags: [enemies, brute-shadow, ai, facing, hitbox]
related: [playtests/2026-10-06-map, bugs/pogo-over-a-guardian-is-a-free-ride]
created: 2026-10-06
updated: 2026-10-06
source_files:
  - scenes/characters/components/ai_controller.gd
  - scenes/characters/enemies/enemy.gd
  - scenes/characters/enemies/brute_shadow/brute_shadow_ai.gd
  - tests/scenes/characters/enemies/brute_shadow/brute_shadow_ai_test.gd
---

## Summary

`Enemy` turned only toward its movement direction, and `BruteShadowAI` stands still (direction 0)
inside `attack_range`. A target already in reach on the brute's back was never faced: the brute
swung at empty air every 1.9 s while Ivo stood behind it unhurt.

## Symptom

Map playtest ([2026-10-06-map](../playtests/2026-10-06-map.md), "Outside the map"): Ivo stopped at
x -441 in Downtown, pressed against the `BruteShadow`, was never hit (20 s with the map open, 8 s
without). Stopped at x -518 he was hit at once.

## Root cause

Measured with a probe beside `tools/playtest` (brute every 6 physics frames):

- The brute stands at x -400, authored facing +1 (east). Ivo at -441 is 41 px west, inside the
  90 px `attack_range`.
- While it spawns the AI does not tick. Walking in, Ivo reaches -447.7 before the first tick.
- Its first tick finds the target in range: `_start_attack()`. Waiting out the cooldown, `_chase_tick`
  sets direction 0 in range. `Enemy._process_motion` called `face_towards(_ai.direction)`, which
  ignores 0, so facing stayed +1 for good.
- Each swing put `Hitbox` (monitoring true) at x -364, on the far side: `hb_hits` stayed empty and
  hp stayed 3 for 9.5 s.
- From -518 (118 px) the brute chases first, with direction -1. That turns it, and the first swing
  lands (hp 3 → 2 at t ≈ 2.2).

The same dead zone exists anywhere Ivo crosses to the brute's back while within 90 px (a jump
over it, a roll through it).

## Fix

`AIController.facing_direction` is a facing intent separate from `direction`. It defaults to
`direction`, so other AIs are unchanged. `Enemy` faces by it. `BruteShadowAI` returns the target's
side while the target is in reach, and the side a swing was aimed at (`_swing_side`, set in
`_start_attack`) until the swing ends. A swing never flips mid-clip.

After the fix: at -441 the first swing faces -1 and hits at t ≈ 1.65. The walk-in route hits on
the first swing, and -518 is unchanged.

## Prevention

`brute_shadow_ai_test.gd` covers four cases with a real `BruteShadowAI` and `EnemySight`:
- a swing at a target already behind it in reach faces it;
- a swing keeps its side;
- waiting out the cooldown in reach turns it without walking;
- out of reach it faces where it walks.

The first case fails on the old `BruteShadowAI`, with facing 0 where -1 is expected.
Rule: an enemy that stops to attack needs a facing source other than its movement.
