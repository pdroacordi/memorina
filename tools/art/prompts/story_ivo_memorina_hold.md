---
id: story_ivo_memorina_hold
command: generate
target: res://assets/sprites/characters/ivo/ivo_memorina_hold.png
size: 128x128
frames: 4
view: side
direction: east
no_background: true
source: procedural: tools/art/build_story35_hand_over.py
---
Ivo holding the Memorina through "Essa é… essa é a música dela." and the choice (STORY-35, `docs/knowledge/architecture/story35-memorina-hand-over.md`): Ivo holds it under his chin, breathing, through his line and the choice ("Yes, all (Recommended)", user, 2026-11-22). 4 frames played 0 1 2 3 2 1, durations 0.375 / 0.25 / 0.25 / 0.375 / 0.25 / 0.25 s (1.75 s, the keeper's breath).

Measured by script (2026-11-23). Frame 0 = `ivo_memorina_lower.png` frame 1 exactly (file (52..85, 32..95); the flute hand at (80..85, 58..64)). Frame 1: his head 2 px up (everything above row 52 moves up, the neck repeats 2 rows). Frame 2: everything above row 70 2 px up (shoulders, arms, flute, head). Frame 3: frame 2 with the flute hand (file columns 76 and over, rows 50..71) back on frame 0's pixels. Nothing else changes, so nothing flickers (`bugs/the-mentors-new-strips-redraw-the-figure-between-frame-0-and-frame-1`). Feet row 95, centroid 64.5 in every frame.

Made procedurally from our own frame by `python -I tools/art/build_story35_hand_over.py`: a PixelLab animate-with-text-v3 take from `tools/art/sources/story/ivo_memorina_lower_f1_2x.png` redrew 17-40% of his pixels each frame, and locked to the still (`lock_to_still.py`) it doubled his face, so it was dropped. Colours: `ivo_memorina_lower.png`'s only.
Negative: outlines, black contour, front view, glow, text, ground, scenery, playing, blowing
