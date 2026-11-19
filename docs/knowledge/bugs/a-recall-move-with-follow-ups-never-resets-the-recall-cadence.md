---
id: bugs/a-recall-move-with-follow-ups-never-resets-the-recall-cadence
type: bug
title: A recall move given follow_ups chains on a cadence-due recall, so the string's last link is not the recall move, _since_recall is never reset and every following string is the recall again
status: fixed
severity: low
tags: [grd-12, guardian, recall, strings, repertoire, invariants, latent]
related: [systems/guardians, architecture/grd-12-guardian-fight-engine]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - scenes/characters/guardians/guardian_repertoire.gd
  - scenes/characters/guardians/guardian_ai.gd
  - tests/scenes/characters/guardians/guardian_move_graph_test.gd
---

## Summary

Data-gated: no shipped recall move has `follow_ups`. Nothing forbids giving one some, and doing so breaks the recall cadence. A link can also be thrown inside the recall's real-time window.

## Symptom

GRD-12 review (code reading). Give `bloom_burst.tres` one `follow_up`. Once `_since_recall >= recall_after_attacks` (a scheduled recall, `_recall_requested` false), the burst chains into the link. `_finish_string` then sees the link, not the burst, and the recall is due again on every later string.

## Root cause

- `guardian_repertoire.gd:23` stops linking only on `recall_requested`, not on `move.recall != null`.
- `guardian_ai.gd:383-387` decides the cadence from the string's last attack.
- `guardian_move_graph_test.gd:44-49` asserts that a recall move is never a link and has no spawns. It does not assert that a recall move has no `follow_ups`.

## Fix

Fixed in GRD-12 (2026-11-18). `GuardianRepertoire.next_link` returns null for a recall move, and `guardian_move_graph_test` asserts a recall move has no `follow_ups`. Test: `guardian_repertoire_test.test_a_recall_move_never_chains`.

Not fixed. Either:
- `next_link` returns null when `move.recall != null`, or the invariant test asserts `attack.follow_ups.is_empty()` for a recall move (simplest, matches "a recall move is never a link");
- and/or `_finish_string` keys the cadence on the string's root, not its last link.

## Prevention

Add the invariant to `guardian_move_graph_test.test_every_guardian_keeps_the_engine_invariants`, and a `guardian_repertoire_test` case for a recall root with links.

## Revision (2026-11-18, GRD-14 review)

GRD-14 deliberately relaxed the fix for the Frost charge-back. `next_link` now lets a recall move chain when it is passed `recall_owned` and the move `leaves_cadence_when_owned()`. `guardian_move_graph_test` allows `follow_ups` only on such a move. A move that still teaches never chains, so the cadence reset holds. An owned move is off the cadence (`GuardianAI._recall_move`), so the link it ends a string with does not matter.

`recall_owned` flips mid-strike when the press lands, so a teaching strike's end could have chained (found latent in the GRD-14 review). Fixed the same day: `GuardianAI` reads ownership as the strike begins (`_owned_at_strike`) and passes that to `next_link`, so a strike that began teaching never chains, whatever its follow-ups' stages. Test: `guardian_ai_test.test_a_teaching_charge_never_chains_off_the_press_that_taught_it` (the roll handed over halfway through a stage-1 charge: no charge-back).
