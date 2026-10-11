---
id: bugs/the-frost-swipe-passes-over-ivo-standing-close-to-the-golem
type: bug
title: The Frost swipe passes over Ivo standing 42-63 px from the golem, where his slash and chop still land
status: fixed
severity: medium
tags: [guardians, frost-guardian, hitbox, tuning, combat, core-09]
related: [systems/guardians, bugs/guardian-hitboxes-that-could-not-reach-a-grounded-ivo, playtests/2026-10-11-core09-retune]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/characters/guardians/frost_guardian/frost_guardian.tscn
  - resources/characters/guardians/frost_guardian/frost_swipe.tres
  - scenes/characters/guardians/guardian_ai.gd
  - tests/scenes/combat/combat_reach_test.gd
  - scenes/characters/guardians/bloom_guardian/bloom_guardian.tscn
---

## Summary

After the CORE-09 retune, the Frost swipe and the start of its charge touch a grounded Ivo only between 63.5 and 120.5 px, centre to centre. Between 42 px (the edge of the golem's contact box) and 63.5 px Ivo is safe from the swipe, and his slash (82) and chop (74) both reach the golem from there.

## Symptom

Found in review, not in play. Measured with `Shape2D.collide` on the keyed boxes, the same method as `combat_reach_test`: swipe and charge `[63.5..120.5]`, slam `[18..94]`. The playtest `2026-10-11-core09-retune` punished from 57 px ("a step in to 57 px after the swipe landed the slash and the chop"), which is inside this pocket.

## Root cause

- `frost_guardian.tscn` keys the swipe and charge circle (radius 10) at (92, -70) scaled (3.4, 3.0): an ellipse over x 58..126 and y -100..-40. Ivo's hurtbox (radius 8, height 44 at y -28) reaches up to y -50, so only the bottom 10 px of the ellipse can touch it. At that height the ellipse begins at x 66.7, so Ivo has to stand 63.5 px out or farther.
- `GuardianAI._in_range()` throws a move at any `abs(dx) <= attack_range` (110 for the swipe), not only at the edge. A golem whose cooldown ends with Ivo at 50 px telegraphs the swipe from 50 px. The golem gives ground at `pace_speed` x 78 = 35 px/s during a cooldown, and Ivo can follow it.
- The ContactHitbox (capsule radius 34) reaches 42 px. The slam (`[18..94]`) covers the pocket, but the swipe has weight 2.0 against the slam's 1.2, so most ordinary moves miss.
- `combat_reach_test` measures only the farthest overlap (`_reach`), so it cannot catch a gap on the near side.

## Fix

The art-true fix, with no new range field. The swipe clip (`attack_1`, which the charge also plays) now keys the box to sweep the way the punch does. At 0.5 s, when the smear crosses the body front, it sits at (56, -70) scaled (3.0, 3.0). By 0.5833 s it has slid out to the fist at (92, -70) scaled (3.4, 3.0), with continuous update. Swipe and charge now touch a grounded Ivo from 34.5 to 120.5 px, which covers 42..110. In game (`core09_frost_close.json`), Ivo standing at 47.3 px took the swipe 0.5 s into the swing.

The whole-interval check also caught the Bloom lash. Its box started touching at 39 px against a contact reach of 38.5 on one side, so it moved from x 72 to x 70 and now touches 37.5..102.5.

## Prevention

`combat_reach_test` samples each hit box every physics frame of its hit window. For every move that does not lunge or leap, it asserts the box touches a grounded Ivo at every distance from the contact box's reach (each side, since the contact box does not turn) out to `attack_range`. Rule: a reach test that reports only the maximum overlap misses gaps nearer in.
