---
id: story_ivo_kneel
command: animate3
target: res://assets/sprites/characters/ivo/ivo_kneel.png
size: 128x128
frames: 9
view: side
direction: east
reference: res://tools/art/sources/story/ivo_idle_f0_2x.png
action: drops slowly to one knee, as if his legs gave way, then stays kneeling with his head bowed and one hand on the ground, breathing; always in right-facing profile
keep: 0-8
generate: 8
source: pixellab
---
Ivo back in the present after a flashback, a one-shot ending kneeling (STORY-05, "A volta": Ivo de joelhos onde estava). Design docs/design/drafts/camada_pessoal.md ("Aprovar o rascunho", user, 2026-11-11); art spend approved ("Pode seguir", user, 2026-11-12). PixelLab animate-with-text-v3 from his idle frame 0 (tools/art/sources/story/ivo_idle_f0_2x.png; frames in tools/art/sources/story/ivo_kneel/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/ivo_kneel ivo_kneel tools/art/sources/story/ivo_idle_f0_2x.png <out> --keep=0-8 --floor=95`.
Negative: outlines, black contour, front view, glow, text, ground, scenery
