---
id: ivo_walk
command: animate3
target: res://assets/sprites/characters/ivo/ivo_walk.png
size: 128x128
frames: 8
view: side
direction: east
reference: res://tools/art/sources/story/ivo_idle_f0_2x.png
action: walking forward at a calm, slow pace, a full walk cycle, arms swinging gently; not running
keep: 0-7
generate: 8
source: pixellab
---
Ivo walking, a loop for scenes (he had only a run): "O jogo começa sem quase nada. Precisamos trabalhar melhor com cutscenes." (user, 2026-10-15; STORY-16). PixelLab animate-with-text-v3 from his idle frame 0 (tools/art/sources/story/ivo_idle_f0_2x.png; frames in tools/art/sources/story/ivo_walk/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/ivo_walk ivo_walk tools/art/sources/story/ivo_idle_f0_2x.png <out> --keep=0-7 --floor=95 --centre=36-56`.
Negative: outlines, black contour, front view, glow, text, ground, scenery
