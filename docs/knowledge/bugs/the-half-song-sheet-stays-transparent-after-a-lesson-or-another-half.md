---
id: bugs/the-half-song-sheet-stays-transparent-after-a-lesson-or-another-half
type: bug
title: The half-song sheet stays transparent when the HUD frame was hidden (after a lesson, a call or another half)
status: resolved
severity: medium
tags: [songs, memorina, hud, tween, fade, half-songs, song-14]
related: [architecture/half-songs, systems/songs-and-the-memorina, gotchas/a-killed-tween-never-emits-finished]
created: 2026-10-28
updated: 2026-10-28
source_files:
  - scenes/ui/memorina_hud/memorina_hud.gd
---

## Summary

`MemorinaHud.on_song_half_learned` fades the frame in and then immediately starts the
lesson-sheet close, which kills the fade-in at alpha 0. When the frame was hidden before
the half was taught, the three notes and three blanks are never seen.

## Symptom

Found in the SONG-14 review (not yet playtested). Teach a half (Shift+F9, or later a
creature or songbook) after any event that hid the HUD frame: a lesson (F9 or a guardian),
a guardian's call, or a previous half sheet. The HUD shows nothing. On a fresh world
build, or after a draw/sheathe that left the frame visible, the sheet does show.

## Root cause

`memorina_hud.gd:129-139`, `on_song_half_learned`:
1. `_show_in_slot()` (`:239`) calls `_fade_frame_in()` when `_frame` is hidden: it sets
   `_frame.modulate.a = 0.0`, shows the frame, and starts `_fade_tween` (0 to 1).
2. `_close_lesson_sheet()` (`:229`) runs in the same call: it `kill()`s `_fade_tween`
   (the fade-in, still at alpha 0), then tweens hold, `modulate:a` 0 to 0, and `_frame.hide`.

The lesson path works only because `on_lesson_started` and `_close_lesson_sheet` are
seconds apart (the close is called from `on_note_cue_reached` on the last cue). `Frame` is
visible in `memorina_hud.tscn` and `on_sheathed` never hides it, so the bug appears only
once a lesson close (`_frame.hide` callback), `on_call_staged`/`on_call_opened`, or a
previous half sheet has hidden the frame.

## Fix

Fixed 2026-10-28 (SONG-14, before commit): `MemorinaHud.on_song_half_learned` places the frame and runs one chained tween (fade in, `LESSON_SHEET_HOLD`, fade out, hide), so no close kills a fade-in.

Open. Chain the hold and fade after the fade-in on one tween (fade in, hold
`LESSON_SHEET_HOLD`, fade out, hide), or start the close only after the fade-in tween
finishes. Do not call `_close_lesson_sheet` in the same frame as `_fade_frame_in`.

## Prevention

A `memorina_hud` test that hides the frame, calls `on_song_half_learned`, waits
`fade_in_time`, and asserts `_frame.modulate.a > 0`. No such test was added with SONG-14.
In general, a `kill()`ed tween leaves its property at whatever value it had reached. A
second tween on the same field must start from where the first left it, or run after it.
