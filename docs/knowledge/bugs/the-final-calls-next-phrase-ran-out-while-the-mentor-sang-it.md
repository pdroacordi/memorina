---
id: bugs/the-final-calls-next-phrase-ran-out-while-the-mentor-sang-it
type: bug
title: The final call's next phrase ran out on the window it was chosen in, before the mentor finished singing it
status: resolved
severity: high
tags: [guardians, finale, grd-06, window, call]
related: [systems/guardians, architecture/grd-06-final-battle]
created: 2026-11-01
updated: 2026-11-01
source_files:
  - scenes/characters/guardians/guardian.gd
  - scenes/characters/guardians/finale/guardian_finale.gd
  - tests/scenes/characters/guardians/finale/guardian_finale_test.gd
---

## Summary

A track chosen in a two-track window starts the final call in the same window (`GuardianFinale._call_phrase`). The
guardian then sings the next phrase (2.2 s lead-in plus its notes), but the window kept ticking from the answer that
chose the track, with a few seconds left; it ran out mid-phrase, the answer failed and the mentor relapsed. The final
call could never be finished, by a player or by the bot.

## Symptom

Mentor bot run (2026-11-01): `call_answered` at 52.5 s, `call_opened` for the first final phrase, no
`call_window_opened`, then `call_closed` and RELAPSE at 55.9 s, every two-track window.

## Fix

`Guardian.call_phrase` holds an open window until the phrase ends (`open_window(lead_in + call duration)`); the call's
end reopens it as usual. Test: `guardian_finale_test.test_the_final_calls_phrase_is_sung_inside_a_held_window`.
Evidence: the bot now answers both phrases and the mentor is RESTORED at 69 s.
