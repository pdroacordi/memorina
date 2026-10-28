---
id: bugs/up-on-a-songbook-during-a-hard-landing-is-spent-and-the-book-stays
type: bug
title: Up on a songbook during a hard landing's recovery is spent, drops the other buffers, and the book stays
status: resolved
severity: low
tags: [story-06, found, songbook, up-buffer, landing, gates, player]
related: [systems/found-pieces, architecture/found-pieces, systems/pickups, architecture/half-songs]
created: 2026-10-28
updated: 2026-10-28
source_files:
  - scenes/characters/ivo/player.gd
  - scenes/characters/components/landing_component.gd
---

## Summary

`Player._try_found` gates a songbook with `_free_for_up`, but the book is taken through `learn_song_half`, whose
`_can_take_lesson` also needs `is_still()`, and `is_still()` is false while `is_recovering()`. `_free_for_up` has no
recovery check. So during the 0.75 s after a hard landing, Up on a songbook is spent and the book stays. The same press
takes a letter.

## Symptom

Found in review of STORY-06 (not yet seen in a playtest). Ivo drops onto a songbook ledge hard enough to trigger a
hard landing (`ivo_landing_stats.tres` `hard_land_time = 0.75`). He presses Up during the recovery, or presses it within
`UP_BUFFER` (0.1 s) before touching down. The `look_up` prompt is showing, but nothing happens: no half, no lesson, and
the book still lies there. A jump, roll or attack press buffered in the same frame is also lost. He has to press again
after the recovery.

## Root cause

- `player.gd:697`: `_free_for_up(on_floor)` passes. It checks rolling, attacking, knockback, climbing, wall slide, the
  instrument, the stair, the call and the recall, but not `is_recovering()` (`player.gd:711-720`).
- `player.gd:703-704`: `velocity.x = 0.0`, then `_drop_buffers()` clears the jump, roll, attack and Memorina buffers.
- `player.gd:705`: `learn_song_half` → `_can_take_lesson` (`player.gd:911`) → `is_still()` (`player.gd:473`) is false
  while `_landing.is_recovering()`, so it returns false. `_try_found` returns false, and `_up_buffer` was already zeroed
  at `player.gd:696`.
- The same applies to every other `_can_take_lesson` refusal that `_free_for_up` does not cover. Today the only other
  one is not owning the Memorina, and that refusal is by design (`player_found_test.test_without_the_memorina_the_book_stays`).
  Even there, the other buffers are still dropped for an action that never happened.

## Fix

Not fixed. Two options:

1. Ask the lesson gate before spending anything. Zero `velocity.x`, then refuse with no `_drop_buffers()` when
   `_can_take_lesson(book)` is false. With this option, decide whether a hard landing should keep the press buffered
   (do not spend it) or spend it.
2. Leave the press unspent while `is_recovering()`, so the buffered Up reads the book once recovery ends. This needs a
   buffer longer than `UP_BUFFER`, or a re-press.

In both cases, call `_drop_buffers()` only after `learn_song_half` returned true (or for a letter).

## Prevention

Add a `player_found_test` case: a book under a hard landing's recovery (set `_landing` recovering, or drop Ivo from a
height). It should assert the outcome the fix chooses and that a buffered jump survives a refused book. The
`_free_for_up` comment says "a moment refused for one is refused for all". A pickup that also passes through
`_can_take_lesson` therefore has to share the lesson's gates or check them first.

## Resolution (2026-10-28)

`_try_found` now calls `learn_song_half` before `_drop_buffers()`: a refused lesson spends only the Up press, and jump, roll, attack and Memorina buffers survive. The Up press itself stays spent, as every refused Up press is (`systems/pickups`); a book is read standing still by design (`systems/found-pieces`), so a press during the recovery does not wait for it.
