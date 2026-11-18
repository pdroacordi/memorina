---
id: bugs/the-bloom-overhead-branch-preempts-its-far-pick-by-weight
type: bug
title: Every Bloom move has attack_height 96, so for any Ivo above its feet the overhead branch picks by array order and bypasses the GRD-13 far pick by weight
status: fixed
severity: medium
tags: [grd-13, guardian, bloom, ai, move-selection, situational-pick]
related: [systems/guardians, bugs/the-sun-guardians-roar-never-fires, playtests/2026-11-18-grd12-engine-regression, playtests/2026-11-18-grd13-bloom-fight]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - scenes/characters/guardians/guardian_ai.gd
  - resources/characters/guardians/bloom_guardian/bloom_guardian_stats.tres
---

## Summary

FIXED 2026-11-18. Found (GRD-13 review, 2026-11-18). `GuardianAI._situational_pick` (`guardian_ai.gd:452-462`) runs its overhead branch
whenever `above > 0.0`. It returns the in-range, weight > 0 move with the strictly greatest `attack_height`. All six
Bloom moves leave `attack_height` at 96, so the winner is the first in `attacks` order whose range covers the distance:
lash up to 104 px, pounce to 220, thorn row to 300, seed lob to 320, antler dash to 420. That branch returns before the
new far branch. So the "far picks by weight" rule in `systems/guardians` holds only while Ivo's feet are level or below
the guardian's.

## Symptom

From code reading; the in-air case needs no measurement.
- Ivo jumps to clear a thorn row or the dash, or pogoes. When the clock turns READY during the jump, the move thrown is
  fixed by distance: always the pounce between 104 and 220 px, never the thorn row. The weighted roll is never asked.
- `_next` alternates on each jump. In the air, `_refresh_next` sets the overhead choice. On landing, `_far_opinion`
  returns the kept `_far_pick` because it still reaches. Only the move at the READY instant is visible, so this is a
  bias, not on-screen dithering.
- Standing on level ground depends on float noise. `bugs/the-sun-guardians-roar-never-fires` measured Ivo 0.1 px above
  the lion's feet in its arena, which makes the branch fire on the ground. If bloom_hollow has the same offset, the
  Bloom's whole kit is order-picked by distance: always the lash at the 82 px comfort distance, the thorn row only
  past 220 px. A probe on a flat `WorldBoundaryShape2D` gave Ivo 6e-8 px BELOW the Bloom, so the branch was skipped
  there. The arena was not measured.
- `guardian_ai_timeline_test` puts Ivo exactly level, so its Bloom golden cannot show either case.

## Measured in bloom_hollow (GRD-13 playtest, 2026-11-18)

The level-ground case does happen in the arena, and it costs the whole stage 0 its variety:
- At spawn the Bloom stands at y 288.0, and a grounded Ivo at 287.9 (`[st]` lines of
  `guardian_fight_player_driver.gd`). The guardian keeps 288.0 until its first leap. Since GRD-13 its first move is the
  thorn row, which does not leap, so it stays at 288.0 through all of stage 0. Ivo then reads as 0.1 px "above" it, and every close pick is
  the lash: 7 runs of 7 played the identical stage-0 sequence (thorn row, lash, burst, lash, lash, burst, lash). A pogo run held
  close for 88 s at stage 0 drew 26 lashes, 13 bursts (the recall cadence) and no pounce or thorn row.
- On HEAD the first move is the pounce, which lands it at 287.9. After that the branch is skipped and the HEAD runs drew a
  close pounce (dx 49.5).
- After the lucidity leap the Bloom stands at 287.9. Stage 1 then draws lash, pounce, thorn row and seed lob by weight.

## Root cause

The overhead branch assumes a guardian owns a move taller than the rest, as Frost does with the slam's 150. With uniform
heights it becomes "first listed", and its `above > 0.0` threshold has no tolerance.

## Options at filing

Not fixed. One change fixes this bug and the Sun's roar: give the branch a threshold and a reason to exist. Run it only
when `above` exceeds the lowest available `attack_height` (no lower move can reach that high), or a few px at least.
Below that, fall through to the far and weighted picks. Re-run the four goldens.

## Fix

Fixed 2026-11-18 (GRD-13, `scenes/characters/guardians/guardian_ai.gd`). `_situational_pick` runs the overhead branch
only when `above` exceeds `_lowest_reach()`: the lowest `attack_height` among the choosable moves with weight > 0. Below
it every move reaches Ivo, so height has nothing to prefer, and the pick falls through to the far pick by weight and the
weighted roll. With all six Bloom moves at 96, the branch now runs only for an Ivo more than 96 px up, where none
reaches. Frost (swipe 96, slam 150) still answers an Ivo between 96 and 150 px up with the slam.

Tests: `guardian_ai_test.test_a_far_player_draws_every_reaching_move_by_weight` (Ivo level, 0.1 px and 40 px up: both
reaching moves are thrown over seeded rolls, the one that does not reach never is),
`test_a_player_above_the_lower_moves_draws_the_tall_one`. `guardian_ai_timeline.json` regenerated from the test's output:
Autumn, Sun and Bloom changed, Frost and the mentor did not (`systems/guardians`, "The Bloom Guardian's fight").

## Prevention

A `guardian_ai_test` case: a far Ivo 0.1 px and 40 px above the feet still draws every reaching move by weight. Also a
timeline variant with Ivo 0.1 px high, as the sun bug's Prevention asks.
