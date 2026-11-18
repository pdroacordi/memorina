---
id: story_mentor_still_at_lamp
command: generate
target: res://assets/sprites/world/story/mentor/still_at_lamp.png
size: 86x120
frames: 1
view: side
direction: west
source: procedural: tools/art/recolour_still.py
---
The keeper waiting at the lamp once the four guardians are restored (STORY-38, `docs/knowledge/architecture/story38-the-keeper-wakes.md`): back at his post, facing west to the dark lamp, his back to the hatch, in the stasis grey, the hand raised to the lamp and empty. "De volta à lâmpada (Recommended)" (user, 2026-11-17, Q1); "Mão vazia (Recommended)" (user, 2026-11-17, Q4: the Memorina is Ivo's since the gift). Art contracts first with placeholders meanwhile (Q5 (a), taken by the orchestrator). It is the `StillAtLamp` child of `Props/Mentor` in `lighthouse_top_contents.tscn` (stage Waiting); it replaced the placeholder (`stasis.png` unflipped). Approved: "Aprovar as quatro (Recommended)" (user, 2026-11-17).

Measured: the canvas is `at_lamp.png`'s, 86x120 px at 2x density, feet on the bottom row at canvas x 43, drawn at offset (-43, -120) from his feet at (720, 672), not flipped. `stasis.png` is a pixel-for-pixel recolour of `empty_hand.png`: identical alpha masks (0 of 10320 pixels differ), 4504 opaque pixels, the 12 source colours mapped to 8 greys with no conflicting pixel. `at_lamp.png` was redrawn by Codex in 12 colours of its own, none in `empty_hand.png`'s palette, each 1.4 to 11.4 RGB units from its nearest colour there. So the still is made with no generation: every `at_lamp.png` pixel snapped to the nearest `empty_hand.png` colour, then mapped through the `empty_hand` to `stasis` colour map, by a script beside `cut_inhabitant.py` (`python -I tools/art/recolour_still.py assets/sprites/world/story/mentor/empty_hand.png assets/sprites/world/story/mentor/stasis.png assets/sprites/world/story/mentor/at_lamp.png <out>`). Made that way, with no generation. The flute stays out: `memorina_in_hand.png` is a separate overlay of AtLamp, never part of this still. If the snapped colours band visibly (two neighbouring at_lamp colours meeting one grey), fall back to a Codex still from `at_lamp.png`, `stasis.png` and `empty_hand.png` (our own art only, never a pack sprite: the packs' licences forbid AI training), cut as `story_mentor_at_lamp`.
Negative: outlines, black contour, text, frame, background, scenery, lamp, light, glow, flute, speckle, gradients, blur, front view, colour
