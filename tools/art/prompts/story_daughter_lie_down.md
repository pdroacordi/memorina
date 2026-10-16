---
id: story_daughter_lie_down
command: animate3
target: res://assets/sprites/world/story/daughter/lie_down.png
size: 64x64
frames: 7
view: side
direction: east
reference: res://tools/art/sources/story/daughter_standing_2x.png
action: lies down on her side on the floor, turning her back to the viewer, curling up as if going to sleep, ending lying still
keep: 0-6
generate: 6
source: pixellab
---
The daughter lying down, a one-shot ending lying still; placed on the mattress and flipped so her head lands on the pillow, its last frame is also her rest pose in bed. "Desenhar agora (Recommended)" (user, 2026-10-16; STORY-15 demo). PixelLab animate-with-text-v3 from her standing still (frames in tools/art/sources/story/daughter_lie_down/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/daughter_lie_down daughter_lie_down tools/art/sources/story/daughter_standing_2x.png <out> --keep=0-6 --floor=61`.
Negative: outlines, black contour, front view, glow, text, ground, scenery
