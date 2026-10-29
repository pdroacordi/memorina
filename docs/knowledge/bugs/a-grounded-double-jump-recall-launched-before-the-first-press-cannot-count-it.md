---
id: bugs/a-grounded-double-jump-recall-launched-before-the-first-press-cannot-count-it
type: bug
title: A grounded 2-step jump recall whose first press comes after Ivo has left the ground never counts that step, because the step now waits for a jump that cannot happen
status: resolved
severity: low
tags: [guardians, recall, qte, double-jump, input, grd-07, regression]
related: [systems/guardians, bugs/a-recall-jump-pressed-during-a-swing-counts-a-step-without-jumping, features/recall-in-more-than-one-press]
created: 2026-10-29
updated: 2026-10-29
source_files:
  - scenes/characters/ivo/player.gd
  - scenes/characters/ivo/abilities/ability_recall_component.gd
  - scenes/characters/components/jump_component.gd
  - resources/characters/guardians/bloom_guardian/bloom_burst.tres
---

## Summary

Since the fix for `bugs/a-recall-jump-pressed-during-a-swing-counts-a-step-without-jumping`, a jump
step short of the last counts only on `JumpComponent.jumped`. A recall armed grounded (2 steps) whose
body then leaves the ground without a jump can no longer count step 1: in the air, without
DOUBLE_JUMP (the skill being recalled), no press produces a `jumped`. The Bloom burst does exactly
this to a player who has not pressed yet.

## Symptom

Found by code reading in the GRD-07 review; not reproduced in a playtest.

1. The Bloom burst swings. `Guardian._on_attack_started` calls `begin_recall`. Ivo is inside the
   120 px `trigger_distance`, so `_open_recall` arms at once with `is_on_floor()` true:
   `steps_left` 2. `WorldFreeze.slow()` ramps to 0.2 over 0.12 real s.
2. The burst's hit window opens 0.2 game s into the swing, about 0.76 real s into the 1.6 s window.
   The burst has damage 0 and `knockback_lift` 560, so a player who has not pressed yet is launched.
3. A ground jump stays possible for `coyote_time_max` (0.12 game s, about 0.6 real s at 0.2). After
   that, a press reaches `_notify_recall`, which returns early (`steps_left() > 1`, player.gd:1141).
   `_try_jump` gets no ground jump, and `_double_jump` is disabled because the skill is not owned.
   No `jumped` is emitted, `_on_jumped_for_recall` (player.gd:1145) never runs, and the window
   expires: `skill_recall_missed`, `miss_damage` 1.

On HEAD, the same airborne press counted step 1 and the next airborne press recalled. A first press
in about the last 0.24 real s of the window worked before and now always fails. Walking or being
knocked off a ledge after a grounded arm fails the same way.

## Root cause

`Player._notify_recall` (player.gd:1140-1142) defers every non-final jump step to `jumped`. That is
right when a ground jump is still possible but refused for now (a swing, a roll): the buffered press
becomes the jump later. It is wrong when no jump can ever come from this press, i.e. airborne with no
coyote time and no air jump.

## Fix

Fixed 2026-10-29: `_notify_recall` defers a non-final jump step to `jumped` only while
`_jump.can_ground_jump(is_on_floor())`; otherwise the press is the step.
`player_recall_test.test_a_press_after_a_launch_past_coyote_time_counts` covers it.

## Prevention

Extend `player_recall_test`: arm a grounded 2-step jump recall, launch Ivo (set `velocity.y`, wait
past coyote time), then press jump twice in the air. The double jump must be recalled.
