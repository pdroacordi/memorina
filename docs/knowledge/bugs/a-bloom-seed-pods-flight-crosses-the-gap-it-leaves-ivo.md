---
id: bugs/a-bloom-seed-pods-flight-crosses-the-gap-it-leaves-ivo
type: bug
title: The Bloom seed lob's far pod comes down through the gap beyond the middle patch, so "stand between the patches" is hit when it is thrown from about 250 px or more
status: fixed
severity: medium
tags: [grd-13, guardian, bloom, spawns, lob, fairness, reach-audit]
related: [systems/guardians, bugs/guardian-hitboxes-that-could-not-reach-a-grounded-ivo]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - resources/characters/guardians/bloom_guardian/bloom_seed_lob.tres
  - scenes/characters/guardians/bloom_guardian/spawns/seed_pod.tscn
  - scenes/characters/guardians/spawns/lob/lob.gd
  - tests/scenes/combat/combat_reach_test.gd
---

## Summary

FIXED 2026-11-18. Found (GRD-13 review, 2026-11-18). The seed lob's three pods land 96 px apart around Ivo, which leaves two 48 px gaps. The
far pod's hitbox is live for its whole flight (`Lob._hit_offset`), and it comes down at a shallow angle through the far
gap at Ivo's hurtbox height. At long throws, standing in the middle of the far gap is a hit. `combat_reach_test` checks
only where the patches come to rest (`_smallest_gap`), so it passes.

## Symptom

Found by computation from the shipped data (`hand` 60, default `arc` 120, `size` 10x10 centred on the arc point; Ivo's
hurtbox is a capsule r 8 h 44 centred 28 px above his feet). The guardian is at x 0 and Ivo at distance d. The patches
cover d-96±24, d±24 and d+96±24. Ivo stands at d+48, the middle of the far gap, where the board says to stand:

| d (px) | 160 | 200 | 240 | 280 | 320 |
|---|---|---|---|---|---|
| far pod's depth into Ivo at d+48 (px) | -8.1 (clear) | -4.3 | -0.8 | +2.5 | +5.5 |
| safe Ivo centres in the far gap (x - d) | 32..57 | 32..53 | 32..49 | 32..44 | 32..40 |

At d 320, the seed lob's own `attack_range`, only 8 px of the 32 px of standing room in that gap is safe: the half next
to the middle patch. The near gap (d-72..d-24) stays clear at every distance, because no pod crosses it low. The far
picks make long throws the common case: from 107 px the move is drawn by weight among the moves that reach.

## Root cause

- `Lob._hit_offset` (`lob.gd:37-41`) moves the live hitbox along a parabola from the hand to the landing spot. Near the
  end of the flight (u ≈ 0.85-0.95) the pod is 20-60 px above the floor, inside Ivo's 6-50 px band, over the last
  30-60 px before its spot. That is the far gap.
- `combat_reach_test._smallest_gap` (`combat_reach_test.gd:364-375`) takes each hit's LAST transform and its rest
  width. It never tests the flight samples against an Ivo standing in a gap.

## Options at filing

Not fixed. Options:
- Make the pod harmless in flight and hurt only on landing (its patch and a landing frame). This matches "each bursts
  into a thorn patch" (board, Bloom table).
- Or raise the arc / lower `live` so the descent is steeper. A pod over a gap must stay above 50 px until it is within
  24 px of its spot.
- Extend the spread audit: for every distance, place Ivo at each safe x of each gap and assert that no hit transform of
  any instance touches him.

## Fix

Fixed 2026-11-18. A `Lob` is harmless in flight: `Lob.is_live` returns false, so its hitbox never turns on, and only the
`FloorPatch` it leaves hurts ("each bursts into a thorn patch", the board). This holds for every lob, the Sun's embers
included.

`combat_reach_test.test_every_guardian_spawn_is_fair` now takes only the live samples of each hit (`_live_hit`), audits
a lob through its patch, and for a spread places Ivo every 2 px wholly inside each gap between the resting hits, asserting
that no live sample of any hit touches him (`_struck_in_a_gap`). With the flight made live again the check fails
("seed_pod.tscn hits an Ivo standing in a gap at -55 px (thrown at 24)"); `spawned_attack_test` asserts that a lob never
turns its hitbox on.

## Prevention

Add the gap-standing check above to `test_every_guardian_spawn_is_fair`. It also covers future `AROUND_IVO` and
`ACROSS_ARENA` lobs (the Sun Guardian's embers).
