---
id: bugs/the-mentors-revelation-shatters-before-its-call-opens-a-window
type: bug
title: The mentor's revelation shatters on its 5 s real-time clock before its call opens a window, so the player never plays a note into it
status: fixed
severity: medium
tags: [guardians, mentor, finale, grd-06, grd-17, revelation, call, dissonance, design-contract]
related: [systems/guardians, architecture/grd-06-final-battle, playtests/2026-11-19-grd17-mentor-feel, playtests/2026-11-19-grd17-mentor-fight, playtests/2026-11-01-grd06-restoration]
created: 2026-11-19
updated: 2026-11-19
source_files:
  - scenes/characters/guardians/finale/guardian_finale.gd
  - resources/characters/guardians/finale_stats.gd
  - resources/characters/guardians/mentor/mentor_stats.tres
---

## Symptom

In 5 of 5 runs of the feel pass (`f_ng2`, `f_ng3`, `f_ng4`, `s2h`, `veil`), the revelation went `call_opened` →
`call_closed` **5.00 s later**, with no `call_window_opened` between them. The fight then returns to pressure at stage 2. The
winter windows in the same runs opened their window **5.54 s** after `call_opened` (17.21 → 22.74, 26.51 → 32.05, 19.36 →
24.90). The revelation's peak (freeze frame, shatter) comes about 0.5 s before the player could press a note.

Design 02 §5.1 says the player "nunca solta o controle da Memorina — usa o mesmo input de call-and-response" and "tenta
tocar as duas frequências ao mesmo tempo". As built, the climax plays itself: the player watches 5 s, then the fight
resumes. The implementer's report noted the same and called it unchanged GRD-06 timing. The GRD-06 playtest
(2026-11-01) logged a revelation lasting 8 s (26 → 34 s), so the call got longer after it, or the clock got shorter.

## Root cause

`GuardianFinale` sets `_revelation_started` when the revelation's call opens (guardian_finale.gd:60). `_revelation_level()`
reaches 1.0 at `revelation_max_seconds` (5.0 real, `FinaleStats`). The mentor's call takes `call_lead_in` 2.2 s plus the
sung phrase before the window opens: ~5.5 s in total. So the time cap is shorter than the call, and the note path
(`revelation_notes` 3 mixed notes) never gets a chance.

## Fix

Fixed in GRD-17's fix round (2026-11-19). `GuardianFinale` starts the revelation's real-time clock on the player's
`call_window_opened` (one-shot, connected when the revelation's call opens), not when the call opens; before the window
the level rises only by mixed notes. `FinaleStats.revelation_max_seconds` is 4.0 (was 5.0): time from the window to play
its notes (the first commits, the next three are mixed, 0.45 s apart). Test:
`guardian_finale_test.test_the_revelation_waits_for_its_window_then_peaks_on_its_clock`.
In the fix round's runs the window opened every time and the driver's three mixed notes shattered it. Opening the window exposed `bugs/the-mentors-revelation-fails-on-the-known-songs-third-note`, fixed in the same round.

## Prevention

A `guardian_finale_test` case: with the real `call_lead_in` and phrase, `call_window_opened` fires before the shatter
during the revelation.
