---
id: story_daughter_lower_eyes
command: animate3
target: res://assets/sprites/world/story/daughter/lower_eyes.png
size: 64x64
frames: 5
view: side
direction: east
reference: res://tools/art/sources/story/daughter_standing_2x.png
action: slowly lowers her head and eyes, sad, her shoulders sinking a little, then stays still looking down
keep: 0-4
generate: 4
source: pixellab
---
The daughter lowering her eyes, a one-shot ending held. "Desenhar agora (Recommended)" (user, 2026-10-16; STORY-15 demo). PixelLab animate-with-text-v3 from her standing still (frames in tools/art/sources/story/daughter_lower_eyes/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/daughter_lower_eyes daughter_lower_eyes tools/art/sources/story/daughter_standing_2x.png <out> --keep=0-4 --floor=61 --centre=10-40`.
Negative: outlines, black contour, front view, glow, text, ground, scenery
