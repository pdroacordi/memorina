---
id: story_ivo_push_swing
command: animate3
target: res://assets/sprites/characters/ivo/ivo_push_swing.png
size: 128x128
frames: 7
view: side
direction: east
reference: res://tools/art/sources/story/ivo_idle_f0_2x.png
action: gently pushes something at chest height in front of him with both hands, arms extending forward then returning, a calm repeated push, feet planted; always in right-facing profile
keep: 0-6
generate: 6
source: pixellab
---
Ivo pushing Alba's swing, a loop (STORY-05, flashback 3: Up a cada volta). Design docs/design/drafts/camada_pessoal.md ("Aprovar o rascunho", user, 2026-11-11); art spend approved ("Pode seguir", user, 2026-11-12). PixelLab animate-with-text-v3 from his idle frame 0 (tools/art/sources/story/ivo_idle_f0_2x.png; frames in tools/art/sources/story/ivo_push_swing/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/ivo_push_swing ivo_push_swing tools/art/sources/story/ivo_idle_f0_2x.png <out> --keep=0-6 --floor=95`.
Negative: outlines, black contour, front view, glow, text, ground, scenery
