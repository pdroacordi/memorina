---
id: bugs/the-mentors-revelation-fails-on-the-known-songs-third-note
type: bug
title: Once the revelation opened its window, playing the winter song failed it on the third note, and its clock then shattered the pressure after the relapse
status: fixed
severity: medium
tags: [guardians, mentor, finale, grd-17, revelation, dual-call, dissonance]
related: [systems/guardians, architecture/grd-06-final-battle, bugs/the-mentors-revelation-shatters-before-its-call-opens-a-window]
created: 2026-11-19
updated: 2026-11-19
source_files:
  - scenes/characters/components/dual_call_judge.gd
  - scenes/characters/guardians/finale/guardian_finale.gd
---

## Symptom

After `bugs/the-mentors-revelation-shatters-before-its-call-opens-a-window` was fixed, the dodging driver played the winter
song into the revelation's window (`g2`, `ng4`): note 1 committed, note 2 was mixed, note 3 was `sequence_failed`, and the
fight relapsed. About 4 s later, in the pressure, the revelation's clock still ran and `_shatter` fired outside any
lucidity: the save was marked revealed and the call machinery closed a call that was not open.

## Root cause

- `DualCallJudge`, unsolvable, reset the answer on each mixed note. The next note was judged as a first note again, and a
  note on neither track's first note is the ordinary failure. Before the clock fix nobody could reach the third note.
- `GuardianFinale._process` stopped only when the finale's stage changed or the revelation was seen, not when the fight
  left the lucidity.

## Fix

- The revelation's judge never resets after its first note: every later note is mixed ("sem punição real", design 02
  §5.1). Only a first note on neither track fails it. `dual_call_judge_test.test_the_revelation_mixes_every_note_after_the_first`.
- `_process` stops once the fight is not in LUCIDITY.
  `guardian_finale_test.test_a_revelation_left_unpeaked_never_shatters_the_pressure_after_it`.

## Prevention

A finale change that lets the player act sooner must be run with the answer the player actually knows: the drivers play
the winter song into every window.
