---
id: story_ivo_ribbon
command: animate3
target: res://assets/sprites/characters/ivo/ivo_ribbon.png
size: 128x128
frames: 9
view: side
direction: east
reference: res://tools/art/sources/story/ivo_idle_f0_2x.png
action: looks down at a small cornflower-blue cloth ribbon held in his open hand, lifts it slowly closer to his face and holds it there; always in right-facing profile
keep: 0-8
generate: 8
source: pixellab
---
Ivo holding Alba's ribbon, a one-shot ending held (STORY-05, flashbacks 2 and 4: the ribbon in the world). PixelLab drew the raised open hand but no ribbon; a placeholder ribbon (2x10 px in Alba's ribbon blue, 118 152 199, hanging under the hand) is painted on every frame of the shipped sheet, until the drawn ribbon replaces it. Design docs/design/drafts/camada_pessoal.md ("Aprovar o rascunho", user, 2026-11-11); art spend approved ("Pode seguir", user, 2026-11-12). PixelLab animate-with-text-v3 from his idle frame 0 (tools/art/sources/story/ivo_idle_f0_2x.png; frames in tools/art/sources/story/ivo_ribbon/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/ivo_ribbon ivo_ribbon tools/art/sources/story/ivo_idle_f0_2x.png <out> --keep=0-8 --floor=95`.
Negative: outlines, black contour, front view, glow, text, ground, scenery
