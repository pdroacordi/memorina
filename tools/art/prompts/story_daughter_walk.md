---
id: story_daughter_walk
command: animate3
target: res://assets/sprites/world/story/daughter/walk.png
size: 64x64
frames: 6
view: side
direction: east
reference: res://tools/art/sources/story/daughter_standing_2x.png
action: walking forward at a slow, sad pace, a full walk cycle, her head a little down, her braid swinging
keep: 2-7
generate: 8
source: pixellab
---
The daughter walking, a loop (frames 0-1 and 8 stand still). "Desenhar agora (Recommended)" (user, 2026-10-16; STORY-15 demo). PixelLab animate-with-text-v3 from her standing still (frames in tools/art/sources/story/daughter_walk/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/daughter_walk daughter_walk tools/art/sources/story/daughter_standing_2x.png <out> --keep=2-7 --floor=61 --centre=10-40`.
Negative: outlines, black contour, front view, glow, text, ground, scenery
