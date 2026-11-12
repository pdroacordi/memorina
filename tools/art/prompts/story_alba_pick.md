---
id: story_alba_pick
command: animate3
target: res://assets/sprites/world/story/alba/pick.png
size: 64x64
frames: 8
view: side
direction: east
reference: res://tools/art/sources/story/alba_standing_2x.png
action: bends down to pick a small flower from the ground, then straightens up holding it to her face to smell it
keep: 0-7
generate: 8
source: pixellab
---
Alba, Ivo's late wife, in his flashbacks (STORY-05): red braid tied with a cornflower blue ribbon, freckles, cream linen dress, brown apron; an adult about 26 art px tall at 2x, facing east, feet on the frame's bottom row. Picking a flower, a one-shot (flashback 2). Approved look: "Aprovar a arte" (user, 2026-11-11), the board tools/art/sources/story/alba_concept_codex.png; design docs/design/drafts/camada_pessoal.md ("Aprovar o rascunho", user, 2026-11-11). PixelLab animate-with-text-v3 from her standing still (frames in tools/art/sources/story/alba_pick/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/alba_pick alba_pick tools/art/sources/story/alba_standing_2x.png <out> --keep=0-7 --floor=61 --centre=10-40`.
Negative: outlines, black contour, front view, glow, text, ground, scenery
