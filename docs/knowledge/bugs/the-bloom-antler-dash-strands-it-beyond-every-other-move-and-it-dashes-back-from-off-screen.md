---
id: bugs/the-bloom-antler-dash-strands-it-beyond-every-other-move-and-it-dashes-back-from-off-screen
type: bug
title: The Bloom antler dash ends at the arena edge, beyond every other move's range, so the next move is always another dash, telegraphed off screen
status: fixed
severity: high
tags: [grd-13, guardian, bloom, antler-dash, fairness, readability, far-pick, camera]
related: [systems/guardians, playtests/2026-11-18-grd13-bloom-fight, bugs/the-bloom-overhead-branch-preempts-its-far-pick-by-weight]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - resources/characters/guardians/bloom_guardian/bloom_antler_dash.tres
  - resources/characters/guardians/motion/dash_motion.gd
  - scenes/characters/guardians/guardian_ai.gd
---

## Summary

FIXED 2026-11-18. Found (GRD-13 playtest, 2026-11-18). The dash runs to the arena edge less 48 px. Afterwards Ivo is 410-465 px away.
Only the dash (range 420) reaches that far, so `_far_opinion` takes it without a roll, and the guardian dashes straight
back. The same holds after the relapse: the lucidity leap leaves it ~460 px away, so the first stage-1 move is always
the dash. At that distance the guardian's whole wind-up (0.55 s) and backstep (0.35 s) happen off screen.

## Symptom

Measured with `tools/playtest/scripts/guardian_fight_player_driver.gd` on the working tree (cb5416d6 + GRD-13):
- **Every stage-1 opening was a dash from 411-418 px**, in 7 of 7 runs. Every dash that started past ~400 px followed
  another dash or the relapse: main_nogod2 shows the pairs at 43.0/46.4, 52.7/56.4 and 62.6/66.3, with no other move between them.
  Stage-1 mix in main_nogod2: 8 dashes, 5 bursts, 2 thorn rows, 1 lash in 18 moves.
- **Off screen:** the `[shot]` guardian screen x during the dash telegraph is 664-696 game px (the view is 640 wide,
  the body ±22) in all 5 runs that shot it. Ivo stands ~265-280 px from the left edge. `screenshots/2026-11-18-grd13-bloom-fight/dash_offscreen.png`:
  0.2 s into the telegraph, nothing; at 0.7 s, an antler tip at the right edge; at strike +0.35 s (hitbox live), nothing;
  at +0.45 s the stag enters at full speed.
- The dash covers ~1100 px in ~0.85 s, about 1300 px/s, not the `.tres`'s 800: `DashMotion` raises its speed to reach the
  edge in time. From the screen edge it reaches Ivo in ~0.25 s, about one human reaction time.

## Root cause

- `DashMotion.plan` always ends at `arena edge - margin`, whatever the start.
- `GuardianAI._far_opinion` is a pure range filter. Past 320 px the dash is the only reaching move, so it is chosen
  deterministically.
- The camera follows Ivo, and nothing frames a guardian beyond ~360 px.

## Options at filing

Not fixed. Options (any one breaks the loop; the second fixes the visibility):
- End the dash at a distance past Ivo (e.g. 160 px beyond him), not at the wall.
- Do not let the dash follow itself (a `follow_ups`-free cooldown or a "not twice in a row" rule in the far branch), and
  let the guardian walk in instead when nothing else reaches.
- Throw the dash only from where its wind-up is on screen: cap its range at ~320 px, or frame both bodies.

## Fix

Fixed 2026-11-18.
- **End point.** `DashMotion.past` (px; 0 keeps the run to the wall): the dash stops `past` beyond Ivo, never beyond the
  arena edge less `margin`. Bloom's is 64, inside Ivo's 77.5 px longest swing on the stag, so the 0.5 s recovery can be
  punished where it ends. When the wall leaves no room past a cornered Ivo it stops `past` short of him: in the
  re-measure a dash clamped at the wall ended 5 px from him and its body hit him after the recovery.
- **On screen and at its own speed.** Range 420 -> 260 and strike 1.2 -> 0.9 s: the farthest run (260 + 64 + the 48 px
  backstep) fits the 0.55 s dash window at 800 px/s, so `DashMotion.planned_speed` never exceeds `speed`. Every Bloom
  move's range plus the stag's 22 px half width is at most 320, half the 640 px view centred on Ivo (thorn row and seed
  lob 300/320 -> 280).
- **No dash after a dash.** `GuardianAttack.repeats` (default true); the dash's is false. `GuardianAI._choosable()`
  leaves a non-repeating move out of every pick right after a string it ended; with nothing else reaching, the far
  opinion is empty and the guardian walks in.
- The hit window is keyed off at the clip's end; a backstep with no time before the dash is skipped.

Tests: `bloom_guardian_kit_test.test_the_dash_ends_past_ivo_at_its_own_speed` (the end at Ivo + 64 from 40 to 260 px,
speed at most 800, the wall's margin when cornered), `test_every_move_is_thrown_from_on_screen`,
`guardian_ai_test.test_a_move_that_does_not_repeat_never_follows_itself`, `guardian_motions_test` (the backstep).

## Prevention

A `guardian_ai_test` case: after a dash ends at the edge, the next pick is not the dash. A reach-audit check that every
move's telegraph starts with the guardian inside the 640 px view centred on Ivo.
