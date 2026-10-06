---
id: bugs/the-notebook-list-cannot-scroll-back-up-past-a-hidden-row
type: bug
title: In a scrolled notebook list, Up stops at the top shown row; the rows hidden above it cannot be reached from keys, D-pad or stick
status: fixed
severity: medium
tags: [notebook, ui, focus, scroll, scrollcontainer, input, gamepad]
related: [playtests/2026-10-06-notebook, systems/notebook, gotchas/gui-focus-skips-a-neighbour-wholly-clipped-by-a-scroll-container, gotchas/autowrapped-rows-settle-over-several-sorts]
created: 2026-10-06
updated: 2026-10-06
source_files:
  - scenes/ui/notebook/notebook.gd
  - scenes/ui/notebook/notebook.tscn
---

## Summary

`Notebook._reframe` scrolls the list so the first shown row sits exactly at the top of the
`List` ScrollContainer. The engine's focus search does not move to a control wholly clipped
by a ScrollContainer when the focused control is flush with the clip edge
(`gotchas/gui-focus-skips-a-neighbour-wholly-clipped-by-a-scroll-container`). So once the
Songs list has scrolled, Up does nothing at the top shown row. The rows above it can no
longer be reached until the world is rebuilt.

## Symptom

Reproduced 2026-10-06 in both locales with real key, D-pad and stick events
(`tools/playtest/scripts/notebook_scroll_up_stuck_pt_BR.json`, `..._en.json`, all eight songs
known; `playtests/screenshots/2026-10-06-notebook/up_stuck_at_scrolled_row.png`).

1. E, Left to Songs, Down x7 to the last song. The list scrolls, and the first four rows are
   hidden with the up cue.
2. Up x4 reaches Restless Wind (`song_gale`). Each step works while the row above is still
   partly inside the clip rect, which shows as an empty gap under the title rule.
3. The 5th, 6th and 7th Up, D-pad Up (button 11) and a stick tilt up all leave the focus on
   `song_gale`. The log shows the same `page=song_gale` and
   `rows=[(song_freeze), (song_bell_jar), (song_release), >song_gale, ...]`.
4. Turning to Items and back does not help. The section reopens on the remembered row,
   framed at the top with the same three rows hidden (`f_up_after_return`). Closing and
   reopening the book does not help either.

The same state is reached without scrolling down. Return to Songs while the remembered row
is the 4th one, and `_reframe` frames it at the top with rows 1 to 3 hidden. At the first
visit the same row was shown with all the rows above it (`notebook_pad.json`,
`10_stick_right_songs`). Mouse clicks were not tested; the hidden rows are clipped anyway.

Only a death or a load (a new `Notebook` instance) brings the first rows back. In a full
game this hides the first songs, Hymn of Frost included, which are the ones the design
names as the notebook's safety net (design 02 section 7, "Apoio de memória").

## Root cause

- `_reframe` (`notebook.gd:266`) sets `_list.scroll_vertical = top(first)`. The first shown
  row's top is then exactly the ScrollContainer's clip top, and every row above it lies
  wholly outside the clip rect.
- Godot 4.7.2's directional focus search skips such a row. Measured headless with a bare
  ScrollContainer: focus at the clip edge with the neighbour wholly clipped stays put; a
  neighbour that is partly visible is reached.
- The downward case can fail in the same way when a row's bottom lands exactly on the clip
  bottom. It was not seen in this list, because the rows never filled the page exactly.
- On a section's return, `_reframe` starts `first` from the current `scroll_vertical`. It can
  only move `first` down, so a frame computed from unsettled autowrap sizes is never undone.

## Fix

Fixed 2026-10-06 (UI-03 round 3), at the cause:
- `Notebook._link_known_rows` gives every known row explicit `focus_neighbor_top` / `focus_neighbor_bottom`
  (and `focus_previous` / `focus_next`): the previous and next known row, itself at either end. Up and down
  therefore skip the "? ? ?" rows and never use the engine's geometric search.
- `_reframe` keeps a base row (`_base_first`): 0 when a section is built, else the first row shown when focus
  last moved. Every settling layout pass reframes from it, so a stale pass cannot carry the window down.
- From the base it scrolls only as far as the focused row (or the placeholders after the last known row)
  needs, then pulls rows above back in while every shown row still fits.
- A `Tail` spacer (106 px) under `Rows` lets any row's top reach the list's top, so the scroll is never
  clamped into an empty top line.

Evidence:
- `notebook_test.test_up_and_down_reach_every_known_row_of_a_scrolled_list`: real `ui_down` x7 then `ui_up`
  x7 through `Input.parse_input_event` reach `song_solstice`, then `song_freeze`, with the focused row always
  shown. With the links removed it fails, stopping at `song_root`.
- `test_up_and_down_skip_the_placeholders`.
- `test_returning_to_a_section_keeps_the_rows_above_that_fit`: same rows as the first visit, and the first
  shown row's top equals the scroll.
- `notebook_scroll_up_stuck_en.json` and `_pt_BR.json` rerun windowed: `c_up_1`..`c_up_7` log `song_shadow`,
  `song_rain`, `song_root`, `song_gale`, `song_release`, `song_bell_jar`, `song_freeze`. D-pad Up and the
  return to Songs stay on `song_freeze`. No frame has an empty top line.

## Prevention

`notebook_test` moves focus with `grab_focus`, so it never exercises the engine's neighbour
search. A test that sends `ui_up` through `Input.parse_input_event` from a scrolled list
would have caught this.
