---
id: bugs/the-elders-lighthouse-painting-shows-no-lighthouse
type: bug
title: The elder's lighthouse painting shows no lighthouse, so the STORY-41 close-ups frame an abstract grey picture
status: fixed
severity: medium
tags: [art, props, elder, painting, story-41, opening, cutscene, close-up]
related: [playtests/2026-11-18-story41-elder-story, playtests/2026-10-16-story16-opening, systems/art-pipeline, systems/props, systems/cutscenes]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - assets/sprites/world/props/interiors/elder_house/lighthouse_painting.png
  - tools/art/prompts/interior_elder_house_lighthouse_painting.md
  - tools/art/interior_prop_sizes.json
  - resources/cutscene/story/elder_looks_at_painting.tres
  - resources/cutscene/story/ivo_walks_to_painting.tres
---

## Summary

FIXED 2026-11-18 (verified in play, STORY-41 round 2): the painting was redrawn at 40x56 (scene offset (-20,-56), `painting_view` moved to (410,170)), and it reads as a white lighthouse with a lamp and beam over a cliff and the sea at zoom 1, 3 and 4 (`playtests/screenshots/2026-11-18-story41-elder-story/j_v2_room_zoom1.png`, `k_v2_closeup_zoom4.png`, `l_v2_closeup_zoom3.png`). Was: OPEN, medium (STORY-41 playtest). `lighthouse_painting.png` is 18x26 art px. Inside its frame (16x22) it has a pale sky over dark
blue-grey and brown blocks: no tower, no lamp, no white shape. Its contract asks for "the framed painting of a white lighthouse on a
cliff". STORY-41 now frames this painting at zoom 4 (`elder_looks_at_painting`) and zoom 3 (`ivo_walks_to_painting`) so that the
elder's "lá" and the girl's "aí" have something to point at. The close-ups show it crisp and whole, but it does not read as a
lighthouse.

## Symptom

- `playtests/screenshots/2026-11-18-story41-elder-story/b_closeup_zoom4.png`: the zoom-4 hold (1.6 s) shows a small framed picture
  of grey-green sky and dark blocks in the middle of a timber wall.
- `c_painting_source_vs_closeup.png`: the source PNG at 16x (left) and the in-game close-up (right) match pixel for pixel, apart
  from the room's grade. The renderer is not at fault: the art itself has no lighthouse.
- `f_closeup_zoom3_ivo_under.png`: the same at zoom 3, with Ivo below it.

## Root cause

The prop was cut from the Codex board with `--size=lighthouse_painting:h13 --flat=7` (`tools/art/interior_prop_sizes.json`), at
2x density. At 13 art px tall, with 7 colours and specks repainted, the tower on the board did not survive. At zoom 1 nobody had
to read it. The STORY-41 close-ups are the first time the player is asked to.

## Fix direction (not applied)

Redraw the painting (art contract first, per `systems/art-pipeline`) so that a white tower with a lit or dark lamp reads at 18x26,
or larger if the close-up needs it. Then re-check both close-ups. Code and dialogue need no change: the camera marks frame the
prop correctly.
