---
id: bugs/guardian-hitboxes-that-could-not-reach-a-grounded-ivo
type: bug
title: The Frost Guardian's moves passed over a grounded Ivo, and the Bloom hit circle was halved by an editor resave
status: fixed
severity: high
tags: [guardians, hitbox, tuning, combat, core-09]
related: [systems/guardians, bugs/recall-move-range-exceeds-hitbox-reach, gotchas/scene-resave-buries-real-edits-in-noise, playtests/2026-10-11-core09-retune]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/characters/guardians/frost_guardian/frost_guardian.tscn
  - scenes/characters/guardians/bloom_guardian/bloom_guardian.tscn
  - resources/characters/guardians/bloom_guardian/bloom_burst.tres
  - resources/characters/guardians/frost_guardian/frost_slam.tres
  - tests/scenes/combat/combat_reach_test.gd
---

## Summary

Measured with `Shape2D.collide` on the boxes each clip keys (CORE-09): none of the Frost Guardian's three moves could touch Ivo standing on the floor, and the Bloom burst was thrown from 78 px but reached 41-47.

## Symptom

No report: the Frost fight had no playtest. The only things that could hurt a grounded Ivo in it were the golem's contact box and the body of its charge. In a CORE-09 exchange, the swipe hit him only after the fix.

## Root cause

- **Frost.** The swipe and charge key the hit circle (radius 10) at (92, -76) scaled (3.4, 2.4), spanning y -100..-52. The slam keys (56, -118) scaled (3.0, 5.2), spanning -170..-66. Ivo's hurtbox (the shared `hurtbox.tscn`, radius 8, height 44 at y -28) spans -50..-6, unchanged since it was made. Every move missed a grounded Ivo by 2 px or more.
- **Bloom.** Commit b72c463 ("the region owns its forgetting") resaved `bloom_guardian.tscn` from the editor and changed `CircleShape2D_hit` from the default radius 10 to 5.206483, a dragged-gizmo value. That halved the lash (46..98 became 58..86) and the burst (±70 became ±36). `bloom_burst.attack_range` 78 had been set to 70 + Ivo's 8. The same resave also moved the body, hurtbox and contact capsules from 28 to 43 px radius.

## Fix

- Frost swipe and charge: (92, -70) scaled (3.4, 3.0), y -100..-40, which grazes Ivo's head where the punch passes in the art. The review then found a pocket at 42-63.5 px where this box missed him, so the swipe now sweeps out from (56, -70) at 0.5 s (`bugs/the-frost-swipe-passes-over-ivo-standing-close-to-the-golem`). Slam: (56, -96) scaled (3.0, 7.4), down to y -22. `frost_slam.attack_range` 100 -> 90, since its box reaches 94.
- Bloom hit circle radius back to 10.0, and the lash box moved from x 72 to x 70 so that it touches Ivo from the contact box's reach. `bloom_burst.attack_range` 78 -> 72, since the burst reaches 75 on its near side (its box sits 3 px off centre).
- The 43 px Bloom capsules are left as they are: they match the 84 px shrub.

## Prevention

`tests/scenes/combat/combat_reach_test.gd` instantiates each guardian scene without adding it to the tree. It reads each move's Hitbox transform at the first hit frame of its clip and scans the distance at which the box overlaps Ivo's hurtbox. It asserts `attack_range <= reach` for every move that does not lunge or leap, and that every move touches a grounded Ivo somewhere. This replaces the "not asserted" note in `bugs/recall-move-range-exceeds-hitbox-reach`. Rule: after an editor resave, read every shape value in the diff, not only the edit you meant to make.
