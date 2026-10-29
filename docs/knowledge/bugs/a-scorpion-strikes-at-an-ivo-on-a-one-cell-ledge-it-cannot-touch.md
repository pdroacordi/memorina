---
id: bugs/a-scorpion-strikes-at-an-ivo-on-a-one-cell-ledge-it-cannot-touch
type: bug
title: A creature's reach box reaches higher than its move's hitbox, so a scorpion strikes again and again at an Ivo on a one-cell ledge and never lands
status: resolved
severity: low
tags: [core-13, creatures, enemy-move, reach, hitbox, combat-reach-test]
related: [systems/creatures, bugs/recall-move-range-exceeds-hitbox-reach, bugs/guardian-hitboxes-that-could-not-reach-a-grounded-ivo, bugs/the-brute-walks-under-ivo-when-he-jumps-from-where-it-parks]
created: 2026-10-29
updated: 2026-10-29
source_files:
  - resources/characters/creatures/scorpion/scorpion_strike.tres
  - resources/characters/creatures/scorpion/scorpion_strike_bait.tres
  - resources/characters/creatures/boar/boar_charge.tres
  - scenes/characters/creatures/scorpion/scorpion.tscn
  - scenes/characters/enemies/enemy_ai.gd
  - tests/scenes/combat/combat_reach_test.gd
---

## Summary

`EnemyAI._move_in_reach` (`enemy_ai.gd:130-134`) starts a move whenever the target's feet lie in
`EnemyMove.reach`. The scorpion's reach runs 56 px up, but its `StrikeHitbox` can touch Ivo's
hurtbox only while his feet are less than 22 px above the scorpion's. An Ivo standing on a 32 px
ledge inside 46 px makes it strike, miss, sit stuck for 0.8 s, and strike again for as long as he
stays there. Found in review (CORE-13 round 1). No round-1 placement has such a ledge, so nobody
has seen it in play yet.

## Details

- Reach: `scorpion_strike.tres:11` and `scorpion_strike_bait.tres:11`, `Rect2(0, -56, 46, 64)`,
  so y -56..8 from the feet.
- Hitbox: `scorpion.tscn:434`, a 28x26 box at (24, -15), so y -28..-2.
- Ivo's hurtbox: the default `hurtbox.tscn` capsule (r 8, h 44 at y -28; `ivo.tscn` does not
  override it), so feet-50..feet-6.
- The two overlap vertically only when Ivo's feet are between 22 px above and 48 px below the
  scorpion's (`-22 < dy < 48`). For `dy` from -56 to -22 the strike is thrown and cannot connect.
- Failing case: Ivo stands on a one-cell (32 px) step or a one-way ledge, 20-46 px in front of a
  scorpion that is ready. `WalkerAI._approach_tick` parks it (`|dx| <= 36`), the reach holds, it
  telegraphs 0.7 s, whiffs, and is stuck 0.8 s, over and over. Each cycle is a free punish
  window, and the creature can be farmed from the step.
- The boar has the same gap: reach y -64..16 (`boar_charge.tres:11`) against a charge box
  spanning y -23..-1. Over a one-way ledge it charges underneath for up to 360 px. Against a
  solid step the wall dazes it, which the design allows ("dazed by a wall").
- `combat_reach_test.test_every_creature_move_lands_over_the_whole_reach_it_is_thrown_from`
  checks only that `reach` contains y 0 (line 105) and scans x for a grounded Ivo. The vertical
  extent of `reach` is never compared with the hitbox.

## Fix

Not applied. Either cap each `reach.position.y` at the highest foot offset the move's hitbox can
touch (about -22 for the scorpion, -27 for the boar), or keep the tall box only for a lunge.
Extend `combat_reach_test` so that, for every move that does not lunge, the hitbox touches Ivo
standing with his feet at `reach.position.y` and at `reach.end.y`. The round-2 scorpion
placements (`caldera_sun_stair`, `caldera_cistern_bottom`) are where this would first show.

## Prevention

A trigger box and a hit box are two shapes. Test the trigger's corners against the hit box, not
only its horizontal extent on one floor. This is the guardians' `attack_range <= reach` rule
applied to the vertical axis.

## Resolution (2026-10-29)

The reach boxes now stop where the hitbox stops touching Ivo: boar charge `Rect2(0, -16, 192, 32)`, scorpion strikes `Rect2(0, -21, 46, 29)`. `combat_reach_test` raises Ivo to the reach's top and requires the move's hitbox to touch him there.
