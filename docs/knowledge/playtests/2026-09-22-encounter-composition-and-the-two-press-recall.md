---
id: playtests/2026-09-22-encounter-composition-and-the-two-press-recall
type: playtest
title: One slot for the sheet, a title that waits its turn, and a QTE that asks for both presses
status: active
build: 8b9193a + the round-10 changes
area_tested: Bloom Hollow call/answer/lesson, Frost Edge call, the double-jump recall from the ground
tags: [hud, memorina, guardians, qte, recall, composition, lesson]
related: [features/encounter-sheet-slot, features/recall-in-more-than-one-press, playtests/2026-09-22-lesson-polish]
created: 2026-09-22
updated: 2026-09-22
ratings: { fun: 4, fluidity: 4, aesthetics: 4 }
screenshots:
  - screenshots/2026-09-22-encounter-composition/01_listen.png
  - screenshots/2026-09-22-encounter-composition/02_answer.png
  - screenshots/2026-09-22-encounter-composition/03_lesson_notes.png
  - screenshots/2026-09-22-encounter-composition/05_lesson_late.png
  - screenshots/2026-09-22-encounter-composition/10_frost_listen.png
  - screenshots/2026-09-22-encounter-composition/00_recall_grounded.png
---

## What was tested

A throwaway scene (deleted afterwards) drove the Bloom Guardian through a real lucidity
window - hits until the phase opened, the phrase sung out, the answer given inside the
window - and then sat through the restoration lesson, photographing the listening, the
answer, the lesson's notes and the lesson's title. A second pass did the same opening
beat in the lighthouse, where the guardian is twice as tall. A third armed the
double-jump recall with Ivo standing on the ground.

## Findings

- **The sheet used to hop.** Measured on the old build: the call sheet at (368, 12), the
  answer at (376, 86), the lesson wherever the answer had left it. Three placements for
  one object inside six seconds, each jammed against the right edge. It now takes one
  slot for the whole encounter - Bloom (158, 40) for all three beats.
- **Centring the box is not centring the sheet.** The frame's left third is the clef
  ornament, so a box-centred frame puts the notes 34 px right of the screen's axis.
  `NoteSheet.staff_center()` centres the staff instead and the picture squares up.
- **A centred sheet is a hat on a tall guardian.** Measured in the lighthouse: the
  golem's head reaches screen y 120 with its feet at 296, and the slot's frame spans
  40-168 - the head and shoulders were completely hidden, which is what the old
  "side away from the guardian" rule had been protecting. The slot now asks
  `Guardian.body_height()` (84 px for the shrub, 176 for the golem) and stands aside
  above `CENTRE_CLEARANCE`. Both guardians read correctly now.
- **The time bar had never been visible.** It was the parchment's own gold drawn on
  parchment. Dark ink now, and it reads at a glance.
- **The [C] key was inside the staff**, where it looked like a note in the wrong place.
  It hangs under the frame now.
- **The title and the sheet used to share the top of the screen** for the first eight
  seconds of the track - the exact frame the user complained about. The title now waits
  for the song's last cue plus 2.2 s, which is after the sheet has bowed out, so the
  lesson reads as a sequence: hear the piece, then learn its name.
- **The double-jump QTE opens on the ground now** and shows two keys with the ring
  hopping from the first to the second as it is given. Before, it waited for the burst's
  lift and could simply never arrive.

## What this cannot judge

Whether the two-press window is generous enough in the hand - the clock is real seconds
at 0.2 time scale (1.6 s, then 1.0 s), which reads as plenty on paper, but nothing here
presses a key under pressure. Likewise whether `CENTRE_CLEARANCE` at 140 px is the right
line: it separates the only two guardians that exist, and a third one near the line is
the case nobody has seen.

## Ratings rationale

- fun 4: the recall is a real act now rather than a thing that happens to you.
- fluidity 4: nothing on screen moves without a reason; the encounter has one place to
  look.
- aesthetics 4: each beat is one element at a time instead of three competing for the
  top of the frame.
