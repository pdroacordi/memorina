---
id: story_daughter_sit
command: animate3
target: res://assets/sprites/world/story/daughter/sit.png
size: 64x64
frames: 7
view: side
direction: east
reference: res://tools/art/sources/story/daughter_standing_2x.png
action: sits down slowly onto a low seat behind her, ending seated with her hands in her lap, head down
keep: 0-6
generate: 6
source: pixellab
---
The daughter sitting down on the bed edge, a one-shot ending held (it reads as a low crouch at this size). "Desenhar agora (Recommended)" (user, 2026-10-16; STORY-15 demo). PixelLab animate-with-text-v3 from her standing still (frames in tools/art/sources/story/daughter_sit/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/daughter_sit daughter_sit tools/art/sources/story/daughter_standing_2x.png <out> --keep=0-6 --floor=61`.
Negative: outlines, black contour, front view, glow, text, ground, scenery
