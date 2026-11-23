---
id: story_mentor_let_go
command: generate
target: res://assets/sprites/world/story/mentor/let_go.png
size: 128x128
frames: 5
view: side
direction: west
no_background: true
source: procedural: tools/art/build_story35_hand_over.py
---
The keeper lets go (STORY-35, `docs/knowledge/architecture/story35-memorina-hand-over.md`): the keeper's empty hand opens, holds 0.5 s and returns to his chest ("Yes, all (Recommended)", user, 2026-11-22). Stood in as `Props/Mentor/LettingGo` (intro `let_go`, 0.1 / 0.5 / 0.15 / 0.15 s, held on 4), then `EmptyHand` is stood in on the identical picture.

Measured by script (2026-11-23). Canvas and offset as `give.png` (world x = 786 - file column, y = 546 + file row). Frame 0 = `give.png` frame 3 exactly: its flute, file (24..37, 64..79), world x 749..762, y 610..625, is the same 180 pixels `ivo_memorina_take.png` frame 0 draws there (160 visible, 20 under Ivo's closing fingers), so the hand-off frame shows one flute whichever sprite changes first. Frame 1 = the same arm without the flute, four 2x2 finger blocks open at its tip (held 0.5 s). Frames 2-3 = `lower.png` frames 2 and 1 (the STORY-37 lower played backward: the arm rising from forward to the chest) with their flute colours removed. Frame 4 = `empty_hand_breathe.png` frame 0 exactly.

Composed, not generated: a PixelLab animate-with-text-v3 take from `tools/art/sources/story/mentor_give_f3_empty_2x.png` (give frame 3 without the flute, mirrored east) never raised the hand and redrew the mask darker each frame, so it was dropped. Built by `python -I tools/art/build_story35_hand_over.py`. Our own art only.
Negative: outlines, black contour, front view, glow, text, ground, scenery, flute
