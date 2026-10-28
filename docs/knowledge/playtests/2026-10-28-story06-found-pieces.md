---
id: playtests/2026-10-28-story06-found-pieces
type: playtest
title: STORY-06 found pieces - letters taken with Up and announced by the quill, their Found pages fit in en and pt_BR; the Redoma songbook shows the half sheet or a full lesson; a songbook refuses Up with no sign while a letter takes it on the run
status: active
build: d130f7b plus STORY-06 uncommitted. Import 17:53:28. player.gd changed at 17:58:28 (the bugs/up-on-a-songbook-during-a-hard-landing fix moved `_drop_buffers` after `learn_song_half`). The letter runs (hut, wreck) ran before it, every songbook run after it. The letter path is the same in both.
area_tested: "woods_hut loft letter (en), frost_wreck_hold bow letter (pt_BR), woods_root_caves alcove Redoma songbook: no halves (half sheet), first half known (full lesson), Up with a direction held, no Memorina; the notebook's Found tab after each take"
tags: [story-06, found, collectibles, songbook, letter, reward-slots, pickups, notebook, quill, half-songs, i18n, playtest]
related: [systems/found-pieces, architecture/found-pieces, systems/notebook, systems/pickups, architecture/half-songs, playtests/2026-10-28-song14-half-songs, playtests/2026-10-06-notebook, bugs/up-on-a-songbook-during-a-hard-landing-is-spent-and-the-book-stays]
created: 2026-10-28
updated: 2026-10-28
ratings: { fun: 3, fluidity: 3, aesthetics: 3 }
screenshots:
  - screenshots/2026-10-28-story06-found-pieces/letter_prompt_in_reach.png
  - screenshots/2026-10-28-story06-found-pieces/letter_zoom_400.png
  - screenshots/2026-10-28-story06-found-pieces/letter_taken_quill.png
  - screenshots/2026-10-28-story06-found-pieces/found_page_en.png
  - screenshots/2026-10-28-story06-found-pieces/found_page_pt_br.png
  - screenshots/2026-10-28-story06-found-pieces/songbook_in_grass_zoom.png
  - screenshots/2026-10-28-story06-found-pieces/songbook_half_sheet.png
  - screenshots/2026-10-28-story06-found-pieces/found_songbook_page_en.png
  - screenshots/2026-10-28-story06-found-pieces/songbook_full_lesson.png
  - screenshots/2026-10-28-story06-found-pieces/songbook_refused_held_and_no_memorina.png
---

# STORY-06: found pieces

## Summary

Every flow in the contract (`systems/found-pieces`) works in the running game:
- A letter lies on its floor line. The Up prompt shows over it in reach. Up takes it within one frame, and the quill fades in (0.42-0.44 at +0.12 s, 1.00 at +0.5 s). No item notice appears.
- E then opens the notebook on the Found tab, with the new entry focused and unread. Title, detail and body sit inside the right page in en and pt_BR.
- The Redoma songbook with no halves known shows the half sheet: three dotted blanks, then notes 4-6.
- With `song_halves [[1,1]]`, the same book runs the full lesson: six notes, the "You learned how to play Lullaby Under Glass" card, then the Redoma pulse.
- Both songbook takes add `found_songbook_bell_jar` to the Found tab and mark the Songs tab unread.

No reproducible bug was found. There are three feel notes:
- **A songbook refuses Up with no sign while Ivo moves, and a letter does not.** The prompt is showing while he runs, so the press feels dropped.
- **Without the Memorina the prompt promises an action that never happens.** This is probably unreachable in normal play.
- **The pickup art reads weakly in grey rooms.** The songbook almost disappears into cave grass.

## Timelines

All files are in `tools/playtest/scripts/`. Every run used a fresh `APPDATA` folder, checked by a probe before the run.

| Timeline | Where | What |
|---|---|---|
| `story06_letter_hut_en` | woods_hut loft, spawn (36420, 12140), walk left 0.32 s | prompt, Up, quill, E, Found page (en) |
| `story06_letter_wreck_pt_BR` | frost_wreck_hold bow plank, spawn (26100, 12110), walk right 0.2 s | the same in pt_BR |
| `story06_letter_on_the_run` | woods_hut loft | Up while running left across the letter |
| `story06_songbook_half` | woods_root_caves alcove, spawn (-4290, 920), walk left 0.25 s | half sheet, Found page |
| `story06_songbook_lesson` | same, `song_halves [[1,1]]`, real clock, 100 s | full lesson, Found page |
| `story06_songbook_held` | same | Up pressed while walking into reach |
| `story06_songbook_held_in_reach` | same | Ivo stands in reach, presses left, Up 0.06 s later (in reach), releases, then Up standing still |
| `story06_songbook_no_memorina` | same, `owned_items [0]` | Up with no Memorina |

Positions:
- woods_hut sits at (36000, 12000), and the slot at cell 10,4 is world x 36336 on the loft (one-way, y 12160, x 36320..36544).
- frost_wreck_hold sits at (25600, 12000), and the slot at 17,3 is x 26160 on the bow plank (y 12128).
- woods_root_caves sits at (-4480, 384), and the slot at 3,16 is x -4368 on the alcove floor (y 928).

**Reach** is decided by Ivo's 12 px `DoorSensor`, not by his 22 px body. With his feet within about 38 px of the slot centre, the prompt shows. A walk that stopped him at 36376.5 (40.5 px from the centre) showed no prompt, and Up did nothing. That was a timing mistake in the timeline, not a bug.

## Findings

1. **Letter at game scale: pass, but weak.**
   - The 16x6 sprite sits exactly on the floor line, centred on the slot. It was measured from pixels: the slot is at world x 36328..36344, and the sprite's bottom row is on the loft top (`letter_zoom_400.png`).
   - In the grey woods_hut, the cream paper is drawn grey-white. The red seal is still visible as a dark speck.
   - At 1x it reads as "a pale scrap on the ledge", not clearly as a letter. You notice it, but it could be a stone or snow.
   - The wreck's bow letter looks the same against the dark hull, with more contrast (`found_page_pt_br.png`, behind the book).
2. **Up prompt in reach: pass.** The prompt shows centred over the slot, 64 + 8 px above its floor, as soon as the sensor overlaps (`letter_prompt_in_reach.png`). It also shows while Ivo runs through the reach.
3. **Taking a letter: pass.**
   - The sprite is gone in the first frame after the press (t 2.72, press at 2.60).
   - The quill reaches 1.00 at +0.5 s. No item notice shows (`notice=0.00` throughout).
   - Ivo has no take pose: he stands idle and the paper vanishes (`letter_taken_quill.png`). The quill, top right, is the only acknowledgement. That is the decision the user made ("Quill only"). Whether it feels enough depends on audio, which this run cannot judge.
   - Up while running also takes a letter, with no stop (`story06_letter_on_the_run`: taken at x 36350, `vel -192`).
4. **Found tab, en: pass.** E opened the notebook straight on the Found section with `found_bento_1` focused and unread (`found_page_en.png`).
   - Title: "Bento's letter, I".
   - Detail: "Letter · Woodcutter's hut" (wraps to two lines).
   - Body: four lines, well inside the page.
   - The list shows the entry, then six "???" rows. The four songbook placeholders sit above it, scrolled out, with the up cue shown.
   - The songbook page "A winter hand's songbook" wraps its title on two lines both in the list and on the page, and still fits (`found_songbook_page_en.png`).
5. **Found tab, pt_BR: pass.** "Diário da Gaivota", "Diário · Porão do naufrágio" (two lines) and a six-line body. The accents render, and everything fits the page (`found_page_pt_br.png`).
6. **Songbook, no halves: pass.**
   - The half sheet is up 0.15 s after the press, with blanks 1-3 and notes 4-6 (`songbook_half_sheet.png`).
   - It stays at full alpha until ~3.95, fades by 4.35 and is gone at 4.75: about 2 s, as SONG-14 measured for F8.
   - The quill fades in alongside it. The world is not paused, and Ivo stays idle.
   - The book is gone, and Found and Songs are both marked unread.
   - The notebook then opened on Found (`found_songbook_bell_jar`), not on Songs.
7. **Songbook, first half known: pass.**
   - Ivo draws the Memorina (t 2.8, `state=memorina_draw`), the tree pauses at 3.2 and the letterbox and six-note sheet show (`songbook_full_lesson.png`).
   - Then the "You learned how to play Lullaby Under Glass" card shows, the tree unpauses at ~83 and the Redoma pulse shows.
   - The quill was held throughout (`holding=true`) and showed only after the lesson (1.00 at 83.5).
8. **Songbook with a direction held: refused as designed, and it feels wrong.**
   - Ivo was standing in reach at -4343. Left pressed at 2.50, Up at 2.56, and at 2.60 he was at -4355, still in reach, running (`vel -192`). Nothing happened: no half, the book stays, and the prompt stays up over a running Ivo (`songbook_refused_held_and_no_memorina.png`, top left).
   - A press of Up after stopping took it (quill 0.50 at +0.15 s).
   - Why it feels wrong:
     - the prompt is visible and promises Up while he moves;
     - the identical gesture takes a letter on the run (finding 3);
     - a refused press is spent at once, not held until he stops, so nothing tells the player why.
   - The player learns "songbooks need a second press", not "stand still".
   - Possible remedies, for the owner to choose: hide or dim the prompt on a songbook while `wants_to_move()`; or keep the Up buffer alive while a direction is held and fire when he stops; or stop him (as `velocity.x = 0` already does) instead of refusing. This is a subjective feel note, not a bug: the contract says a held direction refuses the press.
9. **Songbook without the Memorina: as designed, with a dead prompt.** The prompt shows, Up does nothing, and the book stays with no feedback (`songbook_refused_held_and_no_memorina.png`, bottom right). The fence logic (`X` opens with the Memorina) probably keeps Ivo from ever reaching a songbook without it, so this is low priority. It was not verified in play.
10. **Songbook art: weak in grey caves.**
    - Measured pixel by pixel, the 16x8 book is drawn whole, nothing covers it, and its bottom row sits on the floor line.
    - But greyhushed, it is a grey-purple (#605d6c) slab among grass blades of nearly the same value (#7f8977, #6d7668), and as tall as they are (`songbook_in_grass_zoom.png`). Only its cream page edge reads.
    - At 1x it is easy to walk past. In colour it would be more distinct. Not tested in a coloured spot.
11. **HUD quill hangs over the open notebook.** When the notebook opens while the quill is showing, the quill freezes at full alpha in the top-right corner over the book for as long as the book is open (`quill=1.00` at 6.4 and 7.8 s). It resumes and fades after the close (0.98-0.99 at 9.4 s).
    - This is the pausable toast as built, not STORY-06 code. The 2026-10-06 notebook playtest only saw the case where the quill was already hidden.
    - Cosmetic: it now points at the very entry on screen.

## What screenshots cannot show

- **Audio:** whether a take has a sound, and whether the quill-only acknowledgement feels like enough of a reward for finding a hidden letter. This is the biggest open question for feel, and it needs a human with sound.
- **Latency:** the 0.12 s from press to sprite gone is the frame sampling; the real latency is at most one frame by code. Feel of the songbook refusal is inferred from the logs, not felt.
- **Whether a player notices the pieces** while moving at full speed. The readability notes come from stills at 1x and zoom.
- Camera and lesson pacing were not judged. The lesson flow itself is SONG-14's, covered in `playtests/2026-10-28-song14-half-songs`.

Ratings (low confidence): fun 3, fluidity 3, aesthetics 3. Fun is mostly inferred: the reward moment is a quill and a page, and I could not hear it. Fluidity loses a point for the songbook's silent refusal. Aesthetics loses one for the grey-on-grey pickups.

## Not tested

- The other 15 slots, a `[secret]` slot (z ordering under the closed wall), a death before a bench putting a letter back, and a songbook after F8 (it should vanish with no Found entry).
- The hard-landing case (`bugs/up-on-a-songbook-during-a-hard-landing-is-spent-and-the-book-stays`, fixed at 17:58 during this session) was not re-played.
