---
id: story_alba_chest
command: animate3
target: res://assets/sprites/world/story/alba/chest.png
size: 64x64
frames: 9
view: side
direction: east
reference: res://tools/art/sources/story/alba_seated_2x.png
action: seated on a low seat in profile facing right, she pauses and presses one hand to her chest and catches her breath, then stands up a little too quickly; she stays in profile facing right the whole time
keep: 0-8
generate: 8
source: pixellab
---
Alba, Ivo's late wife, in his flashbacks (STORY-05): red braid tied with a cornflower blue ribbon, freckles, cream linen dress, brown apron; an adult about 26 art px tall at 2x, facing east, feet on the frame's bottom row. The first sign, a one-shot from seated to standing (flashback 2). The hand on the chest must read; she never coughs on screen. Approved look: "Aprovar a arte" (user, 2026-11-11), the board tools/art/sources/story/alba_concept_codex.png; design docs/design/drafts/camada_pessoal.md ("Aprovar o rascunho", user, 2026-11-11). PixelLab animate-with-text-v3 from her seated still (frame 5 of `story_alba_sit`, tools/art/sources/story/alba_seated_2x.png; a standing reference sang standing and turned to face the viewer) (frames in tools/art/sources/story/alba_chest/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/alba_chest alba_chest tools/art/sources/story/alba_seated_2x.png <out> --keep=0-8 --floor=61 --centre=10-40`.
Negative: outlines, black contour, front view, glow, text, ground, scenery
