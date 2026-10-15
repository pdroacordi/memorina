---
id: playtests/2026-10-15-story08-dialogue
type: playtest
title: STORY-08 - the dialogue fixture in the winter trial, a question, the pause over a talk, the answer remembered, the box opposite the speakers
status: active
build: 6e53ead (STORY-08 uncommitted)
area_tested: "trials_winter/winter_trial col 8: the Up prompt, two lines (the elder, a nameless speaker), Esc over a talk and back, the question and its two choices, the reply, the closing line, the second talk whose line follows the answer"
tags: [dialogue, story-08, ui, focus, input, i18n]
related: [systems/dialogue, architecture/dialogue-is-data-and-choices-are-save-facts, systems/screens, systems/input]
created: 2026-10-15
updated: 2026-10-15
ratings: { fun: 3, fluidity: 4, aesthetics: 3 }
screenshots:
  - screenshots/2026-10-15-story08-dialogue/00_prompt.png
  - screenshots/2026-10-15-story08-dialogue/02_line_typed.png
  - screenshots/2026-10-15-story08-dialogue/03_no_name_line.png
  - screenshots/2026-10-15-story08-dialogue/04_paused_over_talk.png
  - screenshots/2026-10-15-story08-dialogue/07_let_go_focused.png
  - screenshots/2026-10-15-story08-dialogue/10_closed_no_jump.png
  - screenshots/2026-10-15-story08-dialogue/11_remembers_the_answer.png
---

# STORY-08: the dialogue fixture

Timeline `tools/playtest/scripts/dialogue_trial.json` (real clock, locale en, raw Up, Z, Down and Escape keys). Run twice: the first run had the box at the bottom; the screenshots here are from the second run (2026-10-15, after the user's "Opposite the speakers (Recommended)"), where it opens at the top.

## What the run showed

- The `look_up` prompt stands over the Talkable while Ivo is in reach (`00`), and hides while the talk runs.
- Up starts the talk: `blocked=true`, focus on `ContinueArea` (log `talking`). Ivo stands low on screen, so the box opens at the top, its panel from art y 20 to 88, clear of the life notes and of Ivo (`02`). The elder's plate hangs under the panel's lower edge and reads "Elder"; the nameless line shows no plate (`03`). The Z next mark sits on the panel's lower edge once a line is typed.
- Esc opens the pause over the talk with the box dimmed under it (`04`); Esc again closes it and the box has focus back (log `after_pause`: `focus=ContinueArea`).
- The question types on one row, the two choices appear under it in ink; Down moves the red ink to "I let it go." (`07`), Z chooses it and the elder's reply follows.
- The Z that ends the talk does not jump (log `closed`: `jump=false floor=true blocked=false`, `10`).
- Up again starts `trial_after`, whose line is the LET_GO variant: "You let it go. I remember." (`11`).

## What screenshots cannot show

- The typing speed (40 chars/s) and the two-press rhythm (complete, then advance) read well in the timing of the steps, but feel is not judged from stills.

## Observations

- First run: the bottom box and its plate covered the lower 45% of the screen, and Ivo's feet sat at the panel's top edge, so a talker beside him would be half hidden. The user chose "Opposite the speakers (Recommended)" (2026-10-15); in the second run the box opens at the top and the whole of Ivo shows (`02`, `07`).
- At the top, a panel at art y 6 (the bottom box's 6 px margin, mirrored) put its frame under the life notes, which draw over it. The top box therefore sits at y 20, under the HUD row (life notes and quill, HUD y 8 to 40).
- A one-line text leaves two empty rows. Expected for a 3-row box.
