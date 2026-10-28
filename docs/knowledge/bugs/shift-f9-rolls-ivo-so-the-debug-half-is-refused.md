---
id: bugs/shift-f9-rolls-ivo-so-the-debug-half-is-refused
type: bug
title: Shift+F9 (debug_learn_song_half) starts a roll on Shift, so the half is refused as Ivo is not still
status: resolved
severity: low
tags: [input, debug, roll, half-songs, song-14]
related: [systems/input, architecture/half-songs]
created: 2026-10-28
updated: 2026-10-28
source_files:
  - project.godot
  - scenes/characters/ivo/player_input.gd
  - scenes/characters/ivo/player.gd
---

## Summary

`roll` is bound to Shift (`project.godot`, `systems/input`). When ROLL is unlocked and the
Memorina is sheathed, the Shift press of Shift+F9 starts a roll before F9 arrives.
`learn_song_half` then fails `_can_take_lesson` (`is_still()` is false while rolling), and
nothing is taught.

## Symptom

Found in the SONG-14 review. With ROLL unlocked and the instrument sheathed, Shift+F9 rolls
Ivo and does nothing else. It works when ROLL is locked, or when the Memorina is drawn,
because `_try_roll` refuses while drawn (`player.gd:1185`). Teaching a half while drawn
has its own defect: `bugs/a-half-taught-while-the-memorina-is-drawn-cannot-be-guessed-until-redrawn`.

## Root cause

`player_input.gd:102` emits `roll_pressed` on the Shift press. `Player._try_roll` consumes
the buffered roll on the next physics step. The F9 press comes a human reaction later and
reaches `_on_debug_learn_song_half_pressed` → `learn_song_half` → `_can_take_lesson`
(`player.gd:880`). `is_still()` (`player.gd:469`) returns false while `is_rolling()`.
The exact-match change at `player_input.gd:119-122` stops F9 from reading Shift+F9, but it
cannot stop Shift from being read as `roll`.

## Fix

Fixed 2026-10-28 (SONG-14, before commit): `debug_learn_song_half` is F8, with no modifier; `systems/input` lists it.

Open. Bind the debug action to a modifier no gameplay action uses (Ctrl+F9, or a free
F-key). Record it in the `systems/input` action table, which does not list
`debug_learn_song_half` yet.

## Prevention

Before binding a debug chord, check that no gameplay action reads its modifier on its own
(the `systems/input` table).
