---
id: playtests/2026-10-29-core04-teaching-creatures
type: playtest
title: CORE-04 teaching creatures. All four teachers are coloured in the grey and sing into a balloon of the current device's glyphs (0.55 s a note, 0.75 s after a mistake). The balloon stays on its teacher through the draw zoom and Ivo's sheet stays hidden. A right echo saves the half with a flourish and the quill, a completing half duets and then plays the full lesson, and a taught teacher sings one lit phrase on a draw. Found that sheathing partway through an echo leaves the balloon lit and the teacher silent
status: active
tags: [core-04, teachers, snail, thrush, kestrel, lizard, echo, balloon, glyphs, duet, lesson, half-songs, notebook, quill, xbox-glyphs]
related: [systems/teaching-creatures, architecture/teaching-creatures, architecture/half-songs, systems/songs-and-the-memorina, bugs/a-sheathe-mid-echo-leaves-the-teachers-balloon-ahead-of-the-instrument, playtests/2026-10-28-song14-half-songs]
created: 2026-10-29
updated: 2026-10-29
source_files:
  - scenes/world/creatures/teaching_creature.gd
  - scenes/world/creatures/teaching_flow.gd
  - scenes/ui/teacher_balloon/teacher_balloon.gd
  - scenes/ui/memorina_hud/memorina_hud.gd
  - scenes/characters/ivo/abilities/memorina_component.gd
  - tools/playtest/scripts/core04_probe_driver.gd
  - tools/playtest/scripts/core04_snail_echo.json
  - tools/playtest/scripts/core04_snail_duet.json
  - tools/playtest/scripts/core04_after_repeat.json
  - tools/playtest/scripts/core04_other_song.json
  - tools/playtest/scripts/core04_thrush.json
  - tools/playtest/scripts/core04_kestrel.json
  - tools/playtest/scripts/core04_lizard.json
  - tools/playtest/scripts/core04_pad.json
  - tools/playtest/scripts/core04_edges.json
  - tools/playtest/scripts/core04_sheathe_mid.json
---

# CORE-04: the four teaching creatures and their balloon duet

## Summary

The flow the user approved (design 02 §2, revised 2026-10-29) works end to end on all four teachers.
- Every teacher is coloured in the grey. The balloon reveals one glyph a note at 0.55 s, shakes on a wrong note,
  then sings again at 0.75 s. A right echo saves the half (notebook "Half a song") with a flourish and the quill.
- With the second half already known, the echo leads into a duet, then the full lesson ("You learned how to play
  LULLABY UNDER GLASS").
- Once taught, a draw nearby brings back one lit phrase. Away from the teacher, play is normal.
- Xbox glyphs follow the pad.

One reproducible bug, confirmed in play (the reviewer had already filed it from a code trace): **sheathing partway through an echo** resets Ivo's echo but not the teacher's count. The
balloon keeps its lit glyphs, the teacher never sings again, and on the next draw one note lights all three.

Ratings (low confidence, from frames and timing, not from feel): **fun 3/5, fluidity 3/5, aesthetics 4/5.** Audio
could not be judged at all, so this needs a human playtest with sound.

## Build and method

- **Build:** the uncommitted CORE-04 working tree on top of `1bea838`. My `--import` ran at 14:34. No `.gd`, `.tscn` or asset
  changed after it.
  - Three data files changed during the first batch: `notebook_catalog.tres` 14:39, `found_catalog.tres` 14:39 and
    `reach_kits.tres` 14:40. The notebook frame comes from the 14:4x real-clock run, after those edits.
- **Runs:** fresh `APPDATA` per run, checked by a headless `OS.get_user_data_dir()` probe before each run.
- **Probe:** every run went through a new `-s` driver, `tools/playtest/scripts/core04_probe_driver.gd`. It wraps the runner and prints:
  - `[probe]` on every change: each teacher's `TeachingFlow` state, singing; the balloon's visibility, box position,
    revealed, lit and shake; Ivo's HUD visible/frame/`_echoing`; echo open, drawn, in lesson; the save's
    first/second/learned halves; the quill alpha; pause and time scale;
  - `[sig]` for Ivo's signals (draw, notes, rejected, failed, reset, echoed, echo open/close, lesson, song).
  - The runner's `log` has none of this, so the probe is what proves timing.
- **Timelines:** I rewrote the six draft timelines and added four (`other_song`, `pad`, `edges`, `sheathe_mid`).

## Results

| Check | Result | Evidence |
|---|---|---|
| Coloured by its own shield in grey regions | **Pass**, all four. Snail blue shell, thrush brown/cream, kestrel rufous, lizard olive/yellow, each against a grey scene | `thrush_kestrel_lizard_true_scale.png`, `snail_sings_reveal_one_glyph_per_note.png` |
| Findable at true scale | Snail, thrush, kestrel: yes. **Lizard: weakest.** It is a flat ~28x8 game-px shape lying on the pit floor, olive on grey, and reads as a twig until it moves | `thrush_kestrel_lizard_true_scale.png` |
| Balloon over its teacher, faces Ivo | **Pass.** The tail points at the head. Every teacher turned to face Ivo (the snail and thrush east, the kestrel and lizard toward him) | all frames |
| Current controller's glyphs | **Pass.** Keyboard arrow keycaps (L R L = ← → ←). With the pad, Xbox **X B X**. The device switched on the first pad press, before the balloon filled | `xbox_glyphs_wrong_note_and_slower_retry.png` |
| One glyph a note, 0.55 s | **Pass.** Lead-in 0.40 s, then reveals at 0.404 / 0.954 / 1.505 s (Δ 0.55), and LISTENING at 2.06 s. Same on all four teachers to ±5 ms. During the 0.4 s lead-in the balloon is empty paper | probe |
| No lag on the draw zoom | **Pass**, measured. During the draw's 0.35 s zoom glide (the tail moved 94 window px), tail x − teacher x stayed 7-9 window px (≤ 1 game px drift). The box keeps its UI size while the world grows | `balloon_stays_on_the_snail_through_the_draw_zoom.png` |
| Ivo's sheet hidden while echoing | **Pass.** `MemorinaHud` stayed invisible from the draw to the half on every teacher, and no frame shows the sheet | probe, frames |
| Wrong note: shake, mistake sound, slower retry | **Pass**, except the sound, which I cannot hear. `sequence_failed` and a 0.3 s ±2 px shake; the lit glyphs drop to 0. `sequence_reset` (the end of the mistake sound) came **1.7-2.9 s** after the wrong note: 2.9 s when the previous right note was still ringing. The retry then reveals at Δ **0.754 s** | probe, pad sheet |
| Right echo: glyphs light, flourish, half saved, quill | **Pass** on all four. Each right note lights its glyph. The third saves the half at once (`first=` bit set) and the quill fades in by +0.35 s. The flourish is a one-shot stretch pose at about +0.3 s. The balloon closes 1.2 s later | `flourish_quill_balloon_lit.png`, `lit_glyphs_yellow_rim.png` |
| Notebook "Half a song" | **Pass.** Songs tab, "Half a song" with ← → ← and three blanks, "Winter · petrified branch", the half-song body | `notebook_half_a_song.png` |
| Half completes the song: duet, then lesson | **Pass.** With `song_halves [[1,2]]`: echo complete at 3.605, DUET with 0.5 s lead-in, duet notes 4.11-5.8 s. At 5.806 the balloon closes and `lesson_started` fires. The full six-note sheet shows, then "You learned how to play / LULLABY UNDER GLASS" for the 79 s track. The pulse plays and the quill shows at 85.7 s | `duet_then_full_lesson_lullaby_under_glass.png` |
| After learning, a draw near brings one lit phrase | **Pass.** TAUGHT_SINGING lights each glyph as it sounds (2.61 / 3.16 / 3.71 s), then the balloon closes 2.0 s after the phrase. Ivo's own sheet is open beside it (no echo, so normal play) and does not overlap | `taught_phrase_returns_beside_ivos_sheet.png` |
| Away from it, normal play | **Pass.** Drawing at x 1400 opens the normal sheet with no balloon, and a note lands on the sheet | same |
| Near an untaught teacher, other songs wait | **Pass.** FREEZE's first note (Up) by the snail is rejected, the balloon shakes and no song plays. At x 1400 the same six notes play FREEZE (`song_played`) | probe, `core04_other_song` |
| Repeat every 4 s | **Pass.** 5.718 → 9.725 s | probe, `core04_edges` |
| An echo note while it sings cuts the phrase | **Pass.** L at 1.25 s during the second sung note: LISTENING, all glyphs shown, lit 1 | probe, `core04_edges` |
| Out of reach closes, back in reach starts over | **Pass.** A teleport out closes the echo and the balloon. Back in reach, it sings from note 1 after the lead-in | probe |
| Sword passes through | Flow unaffected (probe). Frames not studied | `core04_edges` |
| Octave-up voice | **Cannot judge: no audio in screenshots.** Data only: `Call/Voice/AudioStreamPlayer.pitch_scale = 2.0`, `Duet` at 1.0. It is a plain (non-positional) `AudioStreamPlayer`, so the teacher sounds equally loud anywhere in its 256x192 reach | `snail.tscn:206` |

## Findings

1. **Bug (medium): sheathing partway through an echo** leaves the balloon lit and the teacher silent, and the next draw
   over-lights it (`bugs/a-sheathe-mid-echo-leaves-the-teachers-balloon-ahead-of-the-instrument`, `sheathe_mid_echo_keeps_two_lit.png`).
   Reproduced twice in play, which confirms the reviewer's code trace; I added the evidence to that entry. A player who sheathes to "start over" is the likely case: the balloon then claims two of three notes,
   for as long as he waits.
2. **The lit state is low-contrast.** A lit glyph differs from an unlit one only by a 1 game-px pale yellow rim, and its
   red under-shadow turns yellow, both on cream paper (`lit_glyphs_yellow_rim.png`). At true scale, in motion, "which notes
   have I got" may be hard to read. Feel note, not a defect.
3. **A wrong note costs about 4-5 s before the next try.** That is 1.7-2.9 s of Ivo's mistake sound, during which note
   presses are silently dropped (an L at 7.0 s did nothing), plus 2.25 s of the slower retry. The spec allows this ("at no
   cost"), but a press that does nothing with no feedback can feel unresponsive. Inferred from timing; it needs a human
   with sound.
4. **The lizard at the frame edge in the draw zoom.** By the bench pit the zoom leaves the lizard's tail at the left edge.
   The balloon is not clamped to the viewport, so its left edge is cut by ~2-3 game px
   (`lizard_and_balloon_at_the_frame_edge_in_the_draw_zoom.png`). Cosmetic. In the same frame the bench's rest prompt (a
   ↓ keycap in the same style as the balloon's glyphs) floats beside the lizard's R D U balloon, which also contains a ↓.
   That could confuse a first-time player. Low.
5. **On success the instrument sheathes at the third note** (`learn_song_half`: a half arrives sheathed). The camera
   therefore un-zooms at once, and the balloon glides back with it while the flourish plays. Seen in frames; whether it
   reads as a reward or as a cut needs a human.
6. Harness note: a draw pressed while Ivo is still dropping from the spawn (the first ~0.7 s) is refused. Timelines draw
   at 0.9 s or later.

## What screenshots cannot show

The octave-up voice, the mistake sound, the duet's harmony, and whether 0.55 s a note feels like singing or like a
metronome. Also input latency of the echo, and the camera's zoom feel. Every timing above is measured from the probe,
not felt.
