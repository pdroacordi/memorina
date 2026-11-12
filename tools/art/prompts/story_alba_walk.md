---
id: story_alba_walk
command: animate3
target: res://assets/sprites/world/story/alba/walk.png
size: 64x64
frames: 6
view: side
direction: east
reference: res://tools/art/sources/story/alba_standing_2x.png
action: walking forward at a calm, gentle pace, a full walk cycle, her braid and apron swinging
keep: 2-7
generate: 8
source: pixellab
---
Alba, Ivo's late wife, in his flashbacks (STORY-05): red braid tied with a cornflower blue ribbon, freckles, cream linen dress, brown apron; an adult about 26 art px tall at 2x, facing east, feet on the frame's bottom row. Her walk, a loop (frames 0-1 stand still). Approved look: "Aprovar a arte" (user, 2026-11-11), the board tools/art/sources/story/alba_concept_codex.png; design docs/design/drafts/camada_pessoal.md ("Aprovar o rascunho", user, 2026-11-11). PixelLab animate-with-text-v3 from her standing still (frames in tools/art/sources/story/alba_walk/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/alba_walk alba_walk tools/art/sources/story/alba_standing_2x.png <out> --keep=2-7 --floor=61 --centre=10-40`.
Negative: outlines, black contour, front view, glow, text, ground, scenery
