---
id: story_mentor_at_lamp
command: generate
target: res://assets/sprites/world/story/mentor/at_lamp.png
size: 86x120
frames: 1
view: side
direction: west
source: codex
---
The mentor at the lantern before Ivo reaches him (05, Act 3; STORY-34): he stands facing west to the dark lamp, his back to the hatch, his raised hand under it, the flute in that hand: the keeper who stopped lighting it. The user's place: "Na lanterna, junto à lâmpada" (user, 2026-11-17); the still and the turn: "Contrato e provisório (Recommended)" (user, 2026-11-17; `docs/knowledge/architecture/story34-mentor-at-the-lantern.md`, Q4). Until it is approved and drawn, the AtLamp child of `Props/Mentor` in `lighthouse_top_contents.tscn` is the placeholder: `empty_hand.png` unflipped, with `memorina_in_hand.png` unflipped at (683, 574).

Measured (game px, `lighthouse_top`): his feet at (720, 672); the lamp's frame is 64x112 at x 624..688, y 448..560 (`Lamp` at (656, 448), the lens 32 px either side of x 656). His hand stays under the lamp's bottom: the flute's centre at about (683, 574), 37 px west of his feet and 98 px above them, 14 px under the lamp. The canvas is `empty_hand.png`'s: 86x120 px, feet on the bottom row at canvas x 43 (the still sits at offset (-43, -120)), 60 art px tall at 2x density. The flute stays the separate `memorina_in_hand.png` (14x16) laid over the hand, as in Holding, so the hand in this still is drawn empty and open, the flute's place at canvas (-1..13, 14..30) (the canvas's top-left is world (677, 552); the lamp's bottom is canvas row 8). `empty_hand.png` already holds its hand there, so the change is the arm and the mask turned up to the lamp, not the hand's place.

Pose, against our own stills only: the same figure, mask, mantle and colours as `assets/sprites/world/story/mentor/empty_hand.png` (drawn facing west), the near arm raised up and forward toward the lamp rather than held out level, the mask tilted up to it; the other arm at his side; the mantle hanging still. References: `empty_hand.png` and `memorina_in_hand.png` (our own art; never a pack sprite: the packs' licences forbid AI training). Minimalist 16-bit, no outlines, 2x density. Codex image generation, cut by `python -I tools/art/cut_single_prop.py <codex png> <out> --width=0 --height=60 --palette= --parts --flat=12`, as `story_mentor_empty_hand`.
Negative: outlines, black contour, text, frame, background, scenery, lamp, light, glow, speckle, gradients, blur, front view
