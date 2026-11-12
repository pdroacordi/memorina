---
id: story_ivo_sit_ground
command: animate3
target: res://assets/sprites/characters/ivo/ivo_sit_ground.png
size: 128x128
frames: 9
view: side
direction: east
reference: res://tools/art/sources/story/ivo_idle_f0_2x.png
action: sits down slowly on the bare ground, ending seated with his knees drawn up and his arms resting on his knees, looking ahead; always in right-facing profile
keep: 0-8
generate: 8
source: pixellab
---
Ivo sitting down on the grass beside Alba and the sleeping daughter, a one-shot ending seated (STORY-05, flashback 5, Down to sit). Design docs/design/drafts/camada_pessoal.md ("Aprovar o rascunho", user, 2026-11-11); art spend approved ("Pode seguir", user, 2026-11-12). PixelLab animate-with-text-v3 from his idle frame 0 (tools/art/sources/story/ivo_idle_f0_2x.png; frames in tools/art/sources/story/ivo_sit_ground/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/ivo_sit_ground ivo_sit_ground tools/art/sources/story/ivo_idle_f0_2x.png <out> --keep=0-8 --floor=95`.
Negative: outlines, black contour, front view, glow, text, ground, scenery
