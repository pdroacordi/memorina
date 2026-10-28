---
id: bugs/the-struck-ivo-name-widens-the-confirmed-page-past-the-book-in-english
type: bug
title: In English, Redoma's struck name "The One That Keeps the Cold Out" is wider than the right page; the one-line StruckTitle widens the Detail column both ways, so the whole confirmed page runs into the gutter and under the tabs, and the fit test cannot see it
status: resolved
severity: medium
tags: [song-14, notebook, half-songs, struck-title, overflow, i18n, fit-test]
related: [playtests/2026-10-28-song14-half-songs, architecture/half-songs, systems/notebook]
created: 2026-10-28
updated: 2026-10-28
source_files:
  - scenes/ui/notebook/struck_label.gd
  - scenes/ui/notebook/notebook.tscn
  - scenes/ui/notebook/notebook.gd
  - tests/scenes/ui/notebook/notebook_text_fit_test.gd
  - i18n/translations.csv
---

## Summary

On the BY_EAR_CONFIRMED page of Bell Jar (Redoma) in English, the struck name does not fit the right page. The
label never wraps, so its minimum width widens the `Detail` VBox. `Detail` grows to both sides, so every line on
the page moves outward: the body starts in the gutter, and the struck name and the rule run past the book's edge
under the Lore tab. pt_BR ("A que Deixa o Frio Lá Fora") and the other three songs' Ivo names fit.

## Details

- Reproduced in a windowed run (`playtests/2026-10-28-song14-half-songs`, run r3en). The save starts with `song_halves`
  [[1, 1]] and `songs_by_ear` [1]. A `-s` driver then calls `SaveSystem.learn_song_half(1, 2)` (forced: no timeline
  reaches the confirmed state, because the debug half key skips learned songs). After that the notebook opens on
  `song_bell_jar@confirmed`.
  - Screenshot: `playtests/screenshots/2026-10-28-song14-half-songs/confirmed_page_en_overflow_forced.png`, crop
    `confirmed_page_en_overflow_crop.png`.
  - At window scale (2x), the struck text spans x ~942..1170. The page's text column is x ~970..1132 on every other
    page, and the pt_BR confirmed page stays inside it. The body ("A shell of frost...") starts at x ~942 instead of
    ~970.
- Cause:
  - `StruckLabel._ready` sets `AUTOWRAP_OFF` (`scenes/ui/notebook/struck_label.gd:6`), so the label's minimum width
    is its whole string.
  - `Detail` (`scenes/ui/notebook/notebook.tscn:180`) is a full-rect VBox with `grow_horizontal = 2` (both), so it
    widens around its centre.
  - `StruckLabel._draw` caps the line at `size.x` (`struck_label.gd:11`), but `size.x` has already grown, so the line
    is not capped.
- Why the fit test passes: `test_every_half_song_state_fits_both_pages`
  (`tests/scenes/ui/notebook/notebook_text_fit_test.gd:165-169`) compares the string width with `detail.size.x`. That
  is the column the label has just widened, so the assertion holds whatever the length. Compare with the page
  rect (`RightPage`, 81 game px wide), not with `Detail`.

## Gotchas / pitfalls

- A one-line label inside a container is never "too wide" for that container: the container takes the label's
  width. A fit test must measure against a fixed ancestor (the page), not the label's own parent.
- The fix is either content or layout. Content: a shorter English name (user approval needed, it is a drafted text).
  Layout: clip or shrink the struck label (`clip_text`, or `custom_minimum_size.x = 0` with
  `TextServer.OVERRUN_TRIM_ELLIPSIS`). Either way, also correct the test.

## Fix

Fixed 2026-10-28 (SONG-14, before commit): `StruckLabel` sets `clip_text`, so its minimum width no longer widens `Detail`; `notebook_text_fit_test` now compares the struck name and the column with the `RightPage` width, which also caught the pt_BR name; Redoma's Ivo name is shorter ("Keeps the Cold Out" / "Deixa o Frio Fora", a drafted text awaiting the user's approval).
