---
id: bugs/a-floor-gate-with-no-clear-move-re-rolls-the-pick-every-frame
type: bug
title: When every choosable move waits for the floor, the floor gate falls back to them and GuardianAI re-rolls its next move every frame while the floor burns
status: fixed
severity: low
tags: [guardians, ai, pick, floor, waits-for-floor, commit-rule, latent, grd-16]
related: [systems/guardians, bugs/a-pounce-slam-thrown-after-an-ember-spit-cannot-be-walked-out-of]
created: 2026-11-19
updated: 2026-11-19
source_files:
  - scenes/characters/guardians/guardian_ai.gd
---

## Summary

Latent: no shipped guardian reaches it, because the Sun's claw (weight 1.5, stage 0, `repeats` true) never waits. If a
guardian's choosable pool ever holds only `waits_for_floor` moves while its floor burns, `_choosable` returns them
anyway, and `_refresh_next` re-picks every frame. The move is chosen anew by `randf()` each frame instead of being
committed, and it is then thrown into the burning floor.

## Symptom

Found in the GRD-16 fix-round review (code reading). Expected repro: a guardian whose moves at some stage are one
floor-burning move A (does not repeat) and moves B, C that both have `waits_for_floor`. After a string that ends with A,
`_last_end` removes A from the pool, so the pool is B and C only. While A's patches burn, `GuardianAI._next` changes
every physics frame between B and C, by weight, until one is in range. That one is then thrown while the floor burns.

## Root cause

- `guardian_ai.gd:459-465`: the floor filter keeps the unfiltered pool when `clear` is empty, so `_weighted_pick` can
  return a waiting move.
- `guardian_ai.gd:508`: `_refresh_next` re-picks whenever `floor_burning and _next.waits_for_floor`. That condition stays
  true for the waiting move the fallback returned, so the next frame re-picks again. The far branch is stable, because
  `_far_opinion` keeps `_far_pick`. The close and weighted branch rolls again every frame.
- So the commit rule ("Every decision taken from a distance is COMMITTED", `systems/guardians`) fails in this case, and
  the contract that a waiting move is "left out of every pick" does not hold either.

## Fix

Not fixed. Options:
- Hold the pick instead. With no clear move, `_refresh_next` keeps the waiting `_next` and the guardian paces until the
  floor is out. This matches "waits".
- Or forbid the case in data. Add a kit or move-graph invariant that every stage has a choosable non-waiting move with
  weight > 0 after any non-repeating string end. This is what the Sun already satisfies.

## Prevention

Add a `guardian_ai_test` case with only waiting moves and `floor_burning` true. Tick 30 frames with the player out of
range and assert that `_next` does not change. A fallback in a pick filter has to keep the re-pick condition false, or
the per-frame refresh turns it into a per-frame roll.

## Fix (2026-11-19, GRD-16)

`GuardianAI._held_by_floor(attack)` holds a waiting move while the floor burns: `_select_state` does not telegraph it, and `_refresh_next` re-picks only when `_has_clear_move()` finds a choosable move that does not wait. With only floor moves left the kept choice waits for the floor instead of re-rolling every frame or being thrown into the embers. Test: `guardian_ai_test.test_with_only_floor_moves_it_keeps_its_choice_and_waits_for_the_floor`.
