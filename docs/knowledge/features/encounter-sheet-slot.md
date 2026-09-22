---
id: features/encounter-sheet-slot
type: feature
title: An encounter has one slot for the sheet, and it centres the staff rather than the frame
status: active
tags: [hud, memorina, guardians, layout, composition]
related: [features/recall-in-more-than-one-press, playtests/2026-09-22-lesson-polish]
created: 2026-09-22
updated: 2026-09-22
source_files:
  - scenes/ui/memorina_hud/memorina_hud.gd
  - scenes/ui/memorina_hud/note_sheet.gd
  - scenes/ui/guardian_call_hud/guardian_call_hud.gd
  - scenes/ui/lesson_cinematic/lesson_cinematic.gd
---

## Summary

The Memorina's sheet appears three times in one encounter - the guardian sings it, Ivo
answers on it, the lesson lights it - and each of those placed the frame by a different
rule: the call HUD went to the top corner away from the guardian, the answer went beside
Ivo at `answer_center_y`, and the lesson inherited wherever the answer had left it. The
256x128 frame is 40% of a 640x360 screen, so a frame that moves between beats reads as
clutter even when each single placement is defensible.

One slot now: `GuardianCallHud.frame_top` and `MemorinaHud.encounter_top` are the same y
(40), and both centre the frame by its STAFF, not its box.

## Details

- `NoteSheet.staff_center()` answers where the staff's middle falls inside the frame
  (162 px of 256 at 2x). The art's left third is the treble-clef ornament, so centring
  the box on screen leaves the notes - the only part anyone reads - sitting right of
  centre, which is what made the composition look accidental. Centring the staff puts
  the information on the screen's axis and lets the ornament hang off to the left.
- Everything inside the frame shares that axis: the "Listen" message, `CurePips`, the
  answer's time bar. The `draw_memorina` key hangs just below the frame instead of
  floating over the staff, where it read as a note in the wrong place.
- The time bar is dark ink now. It was the parchment's own gold on parchment, which is
  invisible; nobody had noticed because nothing else about it was wrong.
- The sheet no longer waits for `GameCamera.focused` during an encounter. The slot is
  authored, so it is placed the moment it is shown - one less thing that can fail to
  arrive. Free play still waits for the camera, because there the frame goes beside Ivo.
- The lesson's title card waits for the song's last note cue plus `card_delay` (2.2 s,
  covering `MemorinaHud._close_lesson_sheet`'s hold and fade). The sheet and the title
  used to overlap for the first eight seconds of the track, both crowded into the top of
  the frame. The beat is better told in sequence anyway: hear the piece, then learn what
  it is called.

## Why

The frame's size is fixed by its art: at 1x the note glyphs vanish, so 2x is the only
legible size, and a 2x frame cannot share a 360 px screen with a framed pair AND move
around. Given that, the composition has to come from everything else agreeing - one
slot, one axis, one element at a time.
