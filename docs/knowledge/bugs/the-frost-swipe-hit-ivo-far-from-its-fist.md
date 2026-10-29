---
id: bugs/the-frost-swipe-hit-ivo-far-from-its-fist
type: bug
title: Guardian hit boxes touched Ivo where their frame drew nothing
status: fixed
severity: medium
tags: [guardians, frost-guardian, bloom-guardian, hitbox, art, grd-07]
related: [systems/guardians, bugs/the-frost-swipe-passes-over-ivo-standing-close-to-the-golem]
created: 2026-10-29
updated: 2026-10-29
source_files:
  - scenes/characters/guardians/frost_guardian/frost_guardian.tscn
  - scenes/characters/guardians/bloom_guardian/bloom_guardian.tscn
  - tests/scenes/combat/combat_reach_test.gd
---

## Summary

User, 2026-10-29: "A hitbox do guardião do gelo acerta mesmo o sprite estando bem longe." The guardian boxes were sized to reach distances, not to the frames shown in their hit windows.

## Root cause

- The Frost swipe window was frames 6-9 (0.5-0.833 s). Frame 6 holds the arm at head height and frames 9-11 draw it back up; the fist is in Ivo's band only on frames 7-8.
- The hit shape was a `CircleShape2D` scaled non-uniformly. `Shape2D.collide` does not treat it as a true ellipse: a point at (40, 7) collided with a radius-10 circle scaled (5, 1), outside the ellipse. Measured reaches did not match the box the numbers described.
- `combat_reach_test` checked only that a move lands from its contact reach to its `attack_range`, never that the box stays inside the art.

## Fix

- Both guardians' hit shape is a `RectangleShape2D` 20x20; a keyed scale is the half-extent / 10, so the box is exact.
- Every hit window keys the box per frame to the drawn arm, vine, fists or legs (numbers in `systems/guardians`, "Our own art (GRD-07)").
- `test_every_guardian_move_touches_a_grounded_ivo_only_where_its_art_is_drawn`: on each sampled frame of the window, the box's touch distance on a grounded Ivo is at most the frontmost opaque pixel between y -58 (Ivo's drawn height) and the floor, plus Ivo's hurtbox radius (8) plus 4 px.
- `test_every_guardian_move_set_to_reach_higher_lands_that_high`: a move with `attack_height` above the default (96) touches an Ivo raised that high.
