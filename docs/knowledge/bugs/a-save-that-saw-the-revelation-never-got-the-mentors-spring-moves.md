---
id: bugs/a-save-that-saw-the-revelation-never-got-the-mentors-spring-moves
type: bug
title: A save that had seen the revelation never got the mentor's spring moves in a later attempt
status: fixed
severity: medium
tags: [guardians, finale, grd-06, grd-17, revelation, stages, save]
related: [systems/guardians, architecture/grd-06-final-battle, architecture/grd-12-guardian-fight-engine, bugs/a-failed-winter-window-opened-the-mentors-revelation-and-the-final-call-had-to-be-played-twice]
created: 2026-11-19
updated: 2026-11-19
source_files:
  - scenes/characters/guardians/finale/guardian_finale.gd
  - scenes/characters/guardians/finale/finale_fight.gd
  - scenes/characters/guardians/guardian_fight.gd
  - scenes/characters/guardians/guardian.gd
  - resources/characters/guardians/mentor/mentor_stats.tres
---

## Symptom

After a death (or quit) past the revelation, the next attempt at the mentor skipped the revelation window, as designed
("Uma vez por save"), but the pressure stayed winter-only for the rest of the fight: the spring's moves never joined.

## Root cause

The spring moves were swapped in by `Guardian.set_attacks(FinaleStats.revealed_attacks)`, called only from
`GuardianFinale._shatter`. A save with `PlayerData.finale_revealed` never shatters again, so the swap never ran. The
moves were tied to an event of this attempt instead of being derived from the state (revelation seen, winter answered).

## Fix

GRD-17: the spring moves are ordinary `from_stage` 2 moves in `GuardianStats.attacks`; `revealed_attacks` and
`set_attacks` are removed. `GuardianFight.stage()` is `cycles + _extra_stages` (`guardian_fight.gd:198`), and
`Guardian._push_tuning` sets `GuardianFinale.extra_stages()` (`FinaleFight.extra_stages(cycles)`: 1 once revealed, live
or from the save, and `cycles >= winter_cycles`) each time it pushes the stage into the AI. Test:
`guardian_finale_test.test_a_revealed_save_takes_the_spring_after_the_winter_answer`.

## Prevention

Anything a guardian does after a once-per-save event is derived from the saved fact on every attempt, never applied
at the event. The extra stage is read where the stage is pushed (`_push_tuning`), never set by a listener, so no
signal order decides it (review of GRD-17: a `phase_changed` listener had to run before the push).
