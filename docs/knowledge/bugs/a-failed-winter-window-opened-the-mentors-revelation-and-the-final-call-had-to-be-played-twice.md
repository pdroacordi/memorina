---
id: bugs/a-failed-winter-window-opened-the-mentors-revelation-and-the-final-call-had-to-be-played-twice
type: bug
title: A failed winter window opened the mentor's revelation at cycle 0, so the final call ended one cycle short and had to be played twice
status: fixed
severity: medium
tags: [guardians, finale, grd-06, grd-17, revelation, lucidity, cycles]
related: [systems/guardians, architecture/grd-06-final-battle, bugs/a-save-that-saw-the-revelation-never-got-the-mentors-spring-moves]
created: 2026-11-19
updated: 2026-11-19
source_files:
  - scenes/characters/guardians/finale/finale_fight.gd
  - scenes/characters/guardians/finale/guardian_finale.gd
  - tests/scenes/characters/guardians/finale/finale_fight_test.gd
  - tests/scenes/characters/guardians/finale/guardian_finale_test.gd
---

## Symptom

In the final battle, failing the first (winter) lucidity window made the next window the revelation, with no winter
window won. After the revelation the chosen track and both final phrases were answered, but the mentor relapsed
instead of being restored, and the whole two-track window and final call had to be played again.

## Root cause

`FinaleFight.open_window()` counted windows opened (`_windows`), not answers. A failed winter window still counted,
so the second window was REVELATION at `GuardianFight.cycles()` 0. The revelation is dismissed without a cycle, so the
final call's last phrase took `cycles` to 1 of `cycles_to_restore` 2 and relapsed. Design 02 section 5.1 requires
"ter vencido pelo menos uma janela de lucidez normal" before the revelation.

## Fix

GRD-17: `FinaleFight.open_window(cycles)` takes the good answers so far (`finale_fight.gd:35`): WINTER while
`cycles < winter_cycles`, so a failed winter window is winter again. `GuardianFinale.open_call` passes
`fight.cycles()` (`guardian_finale.gd:56`). Tests: `finale_fight_test.test_a_failed_winter_window_is_winter_again`,
`guardian_finale_test.test_the_revelation_is_the_last_stage_of_a_first_attempt`.

## Prevention

The final call ends the fight only if it is the last cycle: `cycles_to_restore` must equal `winter_cycles + 1`. Nothing
asserts that relation yet; changing either number alone brings back the double final call (or restores the mentor
before the revelation). Derive a window's stage from the answers, never from a count of windows opened.
