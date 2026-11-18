---
id: bugs/the-bloom-pounce-cannot-be-walked-under-or-jumped
type: bug
title: The Bloom pounce peaks 48 px, so walking under it is a hit, a single jump does not clear it, and only running away dodges it
status: fixed
severity: medium
tags: [grd-13, guardian, bloom, pounce, fairness, dodge]
related: [systems/guardians, playtests/2026-11-18-grd13-bloom-fight]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - resources/characters/guardians/bloom_guardian/bloom_pounce.tres
  - resources/characters/guardians/bloom_guardian/bloom_pounce_again.tres
---

## Summary

FIXED 2026-11-18. Found (GRD-13 playtest, 2026-11-18). The GRD-13 table in `systems/guardians` and the board say the pounce is dodged by
"walk under, or away". The pounce rises 48 px (legacy leap, impulse 300). Ivo is 54 px tall, and the body and the
pounce box touch him all the way under the arc. At the first fight Ivo has no roll and no double jump, so only running
away works. From stage 1 the pounce comes twice, 192 px each, with a 0.3 s telegraph between the two.

## Symptom

`guardian_fight_player_driver.gd`, working tree (cb5416d6 + GRD-13):
- `PL_POUNCE=under` (walk toward it during the strike): hit 2 of 2. One hit came from the pounce box at dx 6.8 px, with
  the guardian 46 px above Ivo's feet. The other was body contact at dx 17.2, 38 px above (main_god2, t 45.99 and 51.22).
- `PL_POUNCE=jump` (single jump as it closes within 90 px): hit 1 of 1. Ivo was 82 px up, and the guardian's feet
  were 38 px above Ivo's (main_god3 t 37.58).
- `PL_POUNCE=away` (walk away through both telegraphs and strikes): 0 hits in 3 stage-1 double pounces with open
  floor behind Ivo (main_god4, main_nogod1, main_stay1). In main_god1b, an early policy also jumped once the guardian
  was within 70 px, and the second pounce hit it.

Inferred, not played: a double pounce needs ~370 px of floor behind Ivo (192 px/s for 0.45 + 0.6 + 0.3 + 0.6 s). With
his back to a wall it cannot be dodged with the first fight's kit.

## Options at filing

Not fixed. Either make "walk under" true (a pounce peak over ~70 px with no low body contact during the arc, or turn off
contact while airborne), or change the documented dodge to "run away" and keep the second pounce from trapping a
cornered Ivo (e.g. no `pounce_again` when Ivo is within ~200 px of a wall behind him).

## Fix

Fixed 2026-11-18. The pounce and the pounce again are a `LeapMotion` (PAST_IVO, `past` 24, `height` 96, `air_time` 0.5,
inside the 0.6 s strike) instead of the legacy leap (impulse 300, about 48 px). A still Ivo is hit by the leg boxes on the
landing, 24 px past him. One who walks to the arc's middle stands under the body (contact capsule) and the leg boxes,
which pass more than 50 px over his hurtbox's top.

Test: `combat_reach_test.test_the_bloom_pounce_can_be_walked_under`: for both moves, at every 8 px from the comfort
distance (82) to the range (220), an Ivo standing under the arc's middle is touched by neither the contact capsule (every
frame of the strike) nor the leg boxes (the hit window), and the landing is past him. The aimed reach rule (it touches a
standing Ivo at every distance) still holds.

## Prevention

A `combat_reach_test`-style check that every documented dodge succeeds: a scripted Ivo walking under the pounce at
192 px/s takes no hit.
