---
id: playtests/2026-10-28-song14-half-songs
type: playtest
title: SONG-14 half songs - a wrong guess fails on the sixth note, a right guess teaches Redoma under Ivo's name, the half sheet and the notebook's half, by-ear and confirmed pages; the English struck name runs off the page
status: active
build: 5b7028a plus SONG-14 uncommitted; final runs after the 14:04:35 fixes (F8 debug key, one-tween half sheet, sheathe before a half, the guessed half is a lesson)
area_tested: "winter trial (160, 5960), Bell Jar (Redoma): seeded first half, a wrong and a right guess, the lesson card, the notebook's Songs pages; F8 half then F8 completion; by ear then the true half (forced driver); en, the confirmed page also pt_BR"
tags: [song-14, half-songs, memorina, matcher, lesson, notebook, quill, i18n, playtest]
related: [architecture/half-songs, systems/songs-and-the-memorina, systems/notebook, bugs/the-struck-ivo-name-widens-the-confirmed-page-past-the-book-in-english, bugs/the-half-song-sheet-stays-transparent-after-a-lesson-or-another-half, bugs/shift-f9-rolls-ivo-so-the-debug-half-is-refused, playtests/2026-10-06-notebook]
created: 2026-10-28
updated: 2026-10-28
ratings: { fun: 3, fluidity: 3, aesthetics: 3 }
screenshots:
  - screenshots/2026-10-28-song14-half-songs/wrong_guess_fails_on_the_sixth.png
  - screenshots/2026-10-28-song14-half-songs/right_guess_lesson_sheet.png
  - screenshots/2026-10-28-song14-half-songs/lesson_card_ivo_name.png
  - screenshots/2026-10-28-song14-half-songs/notebook_by_ear_page.png
  - screenshots/2026-10-28-song14-half-songs/half_sheet_three_notes_three_blanks.png
  - screenshots/2026-10-28-song14-half-songs/notebook_half_a_song.png
  - screenshots/2026-10-28-song14-half-songs/lesson_card_real_name.png
  - screenshots/2026-10-28-song14-half-songs/confirmed_lesson_card_real_name.png
  - screenshots/2026-10-28-song14-half-songs/confirmed_page_en_overflow.png
  - screenshots/2026-10-28-song14-half-songs/confirmed_page_en_overflow_crop.png
  - screenshots/2026-10-28-song14-half-songs/confirmed_page_pt_br_forced.png
---

# SONG-14: half songs

## Summary

Every flow the user decided on (architecture/half-songs, "User decisions") works in the running game:
- a wrong guess is the ordinary failure, judged on the sixth note;
- a right guess is a full lesson titled with Ivo's name;
- F8 shows three notes and three blanks, then the second F8 is a full lesson under the real name;
- the notebook shows the half, by-ear and confirmed pages, and each change is unread again and announced by the quill, never during a lesson.

One bug: on Redoma's confirmed page in English, the struck name "The One That Keeps the Cold Out" is wider than the page. The whole right page then shifts into the gutter and under the tabs, and the fit test cannot see it (`bugs/the-struck-ivo-name-widens-the-confirmed-page-past-the-book-in-english`).

## Timelines

- `tools/playtest/scripts/song14_half_songs.json`: `song_halves` [[1, 1]], the runner's kit (Memorina owned), `clock` real, en.
  - Draw at 1.5 s.
  - LEFT RIGHT LEFT, then UP UP UP (2.6-4.2 s).
  - LEFT RIGHT LEFT RIGHT UP DOWN (8.0-9.5 s).
  - The lesson; the notebook (E) at 100.5 s.
- `tools/playtest/scripts/song14_half_sheet.json`: nothing known. F8 at 1.5 s, the notebook at 7.5-10 s, F8 at 11.5 s,
  the notebook at 98.5 s. Re-run with the raw `F8` key after the key moved. The first two runs sent the
  `debug_learn_song_half` action and gave the same result.
- `tools/playtest/scripts/song14_confirmed_page.json` with the `-s` driver `song14_confirmed_driver.gd`. The save starts with
  `song_halves` [[1, 1]] and `songs_by_ear` [1]; at 4 s real the driver calls `Player.learn_song_half(bell_jar, SECOND)`.
  F8 skips learned songs, so no timeline step reaches the confirmed state. Frames from this run are labelled forced. An
  earlier pt_BR run made the same state through `SaveSystem.learn_song_half`, with no lesson.
- Build: `song14_half_songs` ran before and after the 14:04:35 fixes (player.gd, player_input.gd, memorina_hud.gd) with
  identical logs. The F8 sheet run and the confirmed run are after the fixes. No game file changed after the last runs
  (`find -newer`).

## Findings

**Wrong guess (works; clarity is a feel concern).**
- Notes 1-5 draw normally. On the sixth, all six keycaps flash red (`wrong_guess_fails_on_the_sixth.png`, 4.3 s) and
  return to blue by 4.7 s. The mistake sound plays to ~7.5 s (`voice_playing`). hp stays 3, and the instrument stays drawn.
- The six failed notes stay on the sheet until the next press, which clears them. A fresh try needs no redraw.
- Inferred, not observed: nothing tells the player that notes 1-3 were right and 4-6 were the guess. A first-time player
  who has seen songs rejected at the first wrong note may read "failed on the sixth" as "the end was wrong". That is the
  intended reading, but only the notebook's "I know how it begins" says so. A human playtest should check whether
  players link the failure to the guess.

**Right guess, a full lesson under Ivo's name (works).**
- At the sixth note the letterbox opens at once and the tree pauses ~1.3 s later (11.1-11.4 s).
- The lesson sheet shows all six notes with no blank and no blue ink (`right_guess_lesson_sheet.png`). Nothing marks
  4-6 as guessed. This is not in the decisions; it is only a note.
- About 6 s in, the card reads "You learned how to play / THE ONE THAT KEEPS THE COLD OUT" (`lesson_card_ivo_name.png`). It is legible and centred, at ~290 window px wide.
- The 79 s track ends at ~90.5 s. The quill shows at 91 s and fades by 95 s. During the lesson `quill` logged 0.00 on
  every line.
- The lesson sheet sits in the encounter slot with its bottom edge on Ivo's hair. That slot is shared with every lesson
  and call, so this is not new to SONG-14.

**Notebook after the guess (works).**
- The notebook opens on Songs, `song_bell_jar*`. Title: "The One That Keeps the Cold Out" (two lines, fits). Notes 1-3
  in ink, 4-6 in Ivo's blue. The body is Ivo's text. The detail line is "Winter · petrified branch"
  (`notebook_by_ear_page.png`).
- Readability of Ivo's ink, from pixels:
  - The pack glyph's arrow (245, 255, 232) on its face (104, 111, 153) becomes (110, 140, 197) on (47, 61, 130).
  - That is roughly half the arrow-to-face contrast. Glyph 4 (RIGHT) is the hardest to read at 1x.
  - The blue does read as "a different hand". The arrows are weaker, but still legible at 2x.

**F8 half sheet (works).**
- The sheet fades in at the top encounter slot with LEFT RIGHT LEFT on the staff and three dotted keycap-sized boxes on
  the middle line (`half_sheet_three_notes_three_blanks.png`).
- The blanks read as empty slots, not as notes: thin dotted slate outlines the size of a keycap.
- The sheet is gone by 3.6 s, ~2 s after the press (LESSON_SHEET_HOLD 1.4 + FADE 0.6, `memorina_hud.gd:13-14`). Inferred:
  that is short for a moment the player may want to memorise. A creature's teaching (CORE-04) should hold longer, or the
  notebook has to be the reference.
- Ivo has no instrument raised while the sheet shows. The quill rises at the same moment (1.6-2.0 s) and fades at ~5.5 s.
  The two do not collide: the quill is top right and the sheet is in the centre slot.
- The notebook opens on "Half a song" with three glyphs and three blanks, the detail line, and "I know how it begins.
  Someone, somewhere, knows how it ends." (`notebook_half_a_song.png`). It fits.
- The second F8 draws the Memorina and starts a full lesson. The card reads "LULLABY UNDER GLASS"
  (`lesson_card_real_name.png`). The quill shows after the lesson (92 s), and the entry is unread again on the next
  opening.

**By ear, then the true half (forced; works except the English page).**
- `Player.learn_song_half(SECOND)` on a guessed song now draws the Memorina and plays a full lesson titled "LULLABY
  UNDER GLASS" (`confirmed_lesson_card_real_name.png`). The quill follows at 84 s, and `song_bell_jar@confirmed` was
  marked read on closing.
- Page in pt_BR (`confirmed_page_pt_br_forced.png`): fits. It has the real title, the struck "A que Deixa o Frio Lá
  Fora", 1-3 in ink and 4-6 still blue, the real body, and the blue margin "Eu tinha acertado.".
- Page in English (`confirmed_page_en_overflow.png`, crop): **the bug.**
  - The struck name spans window x ~942..1170. The rule runs under the Lore tab.
  - The text column, normally x ~970..1132, starts at ~942, so "A shell of frost..." begins in the gutter.
  - Cause: the `StruckLabel` is one line (`struck_label.gd:6`) inside a VBox that grows both ways (`notebook.tscn:180`).
    The fit test compares against that grown VBox (`notebook_text_fit_test.gd:165-169`).
  - The other three Ivo names are short ("Long Afternoon", "Turn and Blow", "Puddle Song").

**Not covered.**
- A half taught after a lesson or a call (the transparent-sheet bug, said to be fixed). Every half in these runs was the
  first sheet of the run.
- Gamepad glyphs and the SECOND-half-first order (notes 4-6 known, 1-3 blank).
- A typo in another known song while a half candidate is installed (Q10, rejected at note 4 or later).

## What screenshots cannot show

- Audio: whether the mistake sting after a six-note phrase feels like "wrong ending" or "wrong song".
- Whether the 1.3 s from the sixth note to the freeze feels like latency.
- The lesson track's fit to Ivo's name.

Fun and fluidity are 3, mostly inferred from timings and the absence of a mid-phrase cue, and need a human playtest.
Aesthetics is 3: the half sheet, blanks and pages read well, but the English confirmed page overflows and Ivo's ink weakens the arrows.
