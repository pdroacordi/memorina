---
id: bugs/a-half-taught-while-the-memorina-is-drawn-cannot-be-guessed-until-redrawn
type: bug
title: A half taught while the Memorina is drawn leaves stale matcher candidates and a full, then hidden, HUD sheet
status: resolved
severity: medium
tags: [songs, memorina, matcher, hud, half-songs, song-14, latent]
related: [architecture/half-songs, systems/songs-and-the-memorina, bugs/the-half-song-sheet-stays-transparent-after-a-lesson-or-another-half]
created: 2026-10-28
updated: 2026-10-28
source_files:
  - scenes/characters/ivo/player.gd
  - scenes/characters/ivo/abilities/memorina_component.gd
  - scenes/ui/memorina_hud/memorina_hud.gd
  - scenes/ui/memorina_hud/note_sheet.gd
---

## Summary

`Player.learn_song_half` accepts a half while the instrument is DRAWN, and a half that does
not complete the song changes neither the component nor the instrument. The matcher keeps
the candidates installed at draw time, so the new half cannot be guessed until the player
sheathes and draws again. The HUD sheet is also left full of the half's six slots, then
hidden, while Ivo is still playing.

## Symptom

Found in the SONG-14 review. It is reachable now through Shift+F9 with the Memorina drawn
(the only way Shift+F9 works with ROLL unlocked, see
`bugs/shift-f9-rolls-ivo-so-the-debug-half-is-refused`). It is reachable later through any
CORE-04 creature or STORY-06 songbook that teaches while the instrument is drawn.
1. Draw the Memorina and press Shift+F9: the first half of Bell Jar is taught.
2. Play the known three notes and a correct guess. The matcher has no partial for Bell Jar
   and rejects the phrase as soon as no learned song admits it.
3. The HUD's notes stop appearing: the six slots are full (`NoteSheet.push_note` drops
   index ≥ 6), and after `LESSON_SHEET_HOLD` the frame fades out and hides with the
   instrument still drawn.

## Root cause

- `player.gd:861-871`: `learn_song_half` on the non-completing path writes the save and
  emits `song_half_learned`, but it does not reinstall candidates or sheathe.
  `MemorinaComponent._half_known` is set only in `try_draw` (`memorina_component.gd:67-76`).
- `memorina_hud.gd:129-139`: `on_song_half_learned` calls `_sheet.show_notes` (six slots)
  and `_close_lesson_sheet` without checking `_drawn`. The close ends in `_frame.hide`.
  Nothing re-shows the frame until the next draw.
- The completing path (`_begin_lesson`) is safe, because the lesson ends in
  `finish_performance` → `sheathe()`.

## Fix

Fixed 2026-10-28 (SONG-14, before commit): `Player.learn_song_half` sheathes a drawn instrument before it shows a half, so the next draw installs the new partial and the sheet is not left full.

Open. Choose one:
- refuse or defer `learn_song_half` while `_memorina.is_drawn()`;
- or sheathe the instrument first, as a lesson does;
- or give the component a way to refresh `_half_known` (re-run `_install_candidates`) and
  have the HUD restore the player's sheet after the half sheet.

The simplest is to sheathe before showing the half, because the half sheet replaces the
player's sheet anyway.

## Prevention

A Player test: draw, `learn_song_half(FIRST)`, then play the right guess and assert
`song_guessed`. The plan listed Player-suite tests for `learn_song_half`, and none was
added.
