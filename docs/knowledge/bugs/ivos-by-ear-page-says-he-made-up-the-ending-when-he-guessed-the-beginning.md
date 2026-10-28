---
id: bugs/ivos-by-ear-page-says-he-made-up-the-ending-when-he-guessed-the-beginning
type: bug
title: Ivo's by-ear notebook body says he made up the ending even when the half he guessed was the beginning
status: resolved
severity: low
tags: [notebook, i18n, half-songs, song-14, content]
related: [architecture/half-songs, systems/notebook]
created: 2026-10-28
updated: 2026-10-28
source_files:
  - i18n/translations.csv
  - resources/ui/notebook/notebook_entry.gd
  - resources/ui/notebook/notebook_catalog.tres
---

## Summary

Each halved song has one `ear_body_key`, but three of the four texts say Ivo invented the
end. Either half can come first (design 02 §7.2.1). When the songbook (notes 4-6) comes
first and Ivo guesses notes 1-3, the page says the wrong half.

## Symptom

Found in the SONG-14 review. Teach `SECOND` of Bell Jar, Gale or Rain, then guess the
first three notes. The BY_EAR page shows:
- `NOTEBOOK_SONG_BELL_JAR_EAR_BODY` "I made up the ending.";
- `NOTEBOOK_SONG_GALE_EAR_BODY` "I guessed the ending.";
- `NOTEBOOK_SONG_RAIN_EAR_BODY` "I made up the end.".

The pt_BR texts have the same problem ("Inventei o fim", "Adivinhei o fim"). Solstice
("I found the rest by ear") is neutral.

## Root cause

`NotebookEntry.body_key_for` (`notebook_entry.gd`) returns `ear_body_key` for BY_EAR without
looking at `guessed_halves`. The texts (`i18n/translations.csv:212-215`) were written for
the creature-first order only. The fit test's `_half_states()` only builds the
FIRST-known, SECOND-guessed order, so it never renders the other order.

## Fix

Fixed 2026-10-28 (SONG-14, before commit): the four by-ear bodies say "the rest" / "the missing notes", true of either half; `notebook_text_fit_test._half_states` builds both orders.

Open. The texts are still waiting on the user's approval (plan question 9). Choose one:
- reword all four so they do not depend on which half was guessed, as Solstice already does;
- or split them into per-half keys and pick one with `guessed_halves`.

## Prevention

When a text can be reached by more than one save path, write it against every path.
Cover both guess orders in `notebook_text_fit_test._half_states()`.
