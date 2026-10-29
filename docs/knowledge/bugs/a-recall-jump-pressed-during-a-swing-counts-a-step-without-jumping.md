---
id: bugs/a-recall-jump-pressed-during-a-swing-counts-a-step-without-jumping
type: bug
title: A jump pressed while Ivo is still swinging when the Bloom burst's recall opens counts as the first step but does not jump, so the recall cannot be finished
status: resolved
severity: medium
tags: [guardians, recall, qte, double-jump, input, grd-07]
related: [systems/guardians, playtests/2026-10-29-grd07-guardian-art, features/recall-in-more-than-one-press]
created: 2026-10-29
updated: 2026-10-29
source_files:
  - scenes/characters/ivo/player.gd
  - scenes/characters/ivo/abilities/ability_recall_component.gd
---

## Summary

The Bloom burst opens a grounded double-jump recall of 2 presses, and the last press must be
airborne. If Ivo is still in a sword swing when the first jump press comes, the press counts
as step 1 but no jump happens. Every later press is on the ground, so it neither counts nor
jumps, and the window runs out: `skill_recall_missed`, 1 damage. This was not caused by GRD-07.
It was found during the GRD-07 playtest because the closer stag makes a player more likely to
be mid-combo when the burst comes.

## Symptom

`playtests/2026-10-29-grd07-guardian-art`, bot run `bbot2` (Ivo comboing Bloom at about 59 px when
the burst swings). From the `[bot]` log:

```
t=6.623 SIG recall_started                       floor=true
t=6.623 JUMP press (armed steps=2 floor=true ts=0.05)
t=6.706 SIG recall_step_taken                    floor=true   <- step counted, no `jumped`
t=6.941 JUMP press (armed steps=1 floor=true ts=0.20)   <- refused (airborne_finish), no jump
t=7.225 JUMP press (armed steps=1 floor=true ts=0.20)
t=7.508 JUMP press (armed steps=1 floor=true ts=0.20)
t=7.685 SIG recall_ended / skill_recall_missed   hp 3 -> 2
t=7.724 SIG jumped                               <- the buffered jump, after the window
```

The next burst in the same run had no swing in progress. There the first press jumped
(`jumped` at 10.480) and the airborne second press recalled. Run `bbot1` missed its first two
bursts the same way.

## Root cause

- `Player._notify_recall` (player.gd:1133) feeds every jump press to
  `AbilityRecallComponent.notify`. This happens whether or not the jump is performed. Step 1 of
  a grounded recall has no `airborne_finish` gate, so it counts.
- The same press reaches `_try_jump` through the jump buffer, and `_try_jump` returns early on
  `is_attacking()` (player.gd:1222). The recall slows the world to 0.05 and then 0.2 time
  scale, so the swing takes about 1 s of real time to end, and the window is 1.6 s.
- From then on `steps_left` is 1, the step must be airborne, and Ivo is grounded.
  `notify` returns false (ability_recall_component.gd:40), and `_try_jump` keeps refusing while
  the swing runs. `_on_skill_recalled` clears a knockback and a landing recovery so the
  remembering press can act, but no code does that for a step taken during a swing.

## Fix

Fixed 2026-10-29. `Player._notify_recall` now acts only on the armed recall's action: it cancels a running sword
swing (`AttackComponent.cancel()`), so the press jumps on the same frame, and a jump step short of the last is
counted on `JumpComponent.jumped` (`Player._on_jumped_for_recall`) instead of on the press. A press another gate
refuses stays buffered and counts when the jump happens. The last step still counts on the press, so its unlock
reaches `_try_jump` on the same frame. Recorded in `systems/guardians`, "Fixes after the GRD-07 playtest and review".

## Prevention

`player_recall_test`: a grounded 2-step jump recall armed mid-swing; the press cuts the swing and jumps, the step
counts on the jump, and the airborne press recalls. A press that never becomes a jump leaves `steps_left` at 2.

## Revision (2026-10-29)

The fix is incomplete. Deferring every non-final jump step to `jumped` also defers presses that can never become a jump: airborne, past coyote time, with DOUBLE_JUMP not yet owned. This is the state the Bloom burst's 560 px/s lift leaves a player in if he has not pressed yet. See `bugs/a-grounded-double-jump-recall-launched-before-the-first-press-cannot-count-it`.
