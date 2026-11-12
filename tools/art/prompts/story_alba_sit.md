---
id: story_alba_sit
command: animate3
target: res://assets/sprites/world/story/alba/sit.png
size: 64x64
frames: 6
view: side
direction: east
reference: res://tools/art/sources/story/alba_standing_2x.png
action: sits down slowly onto a low flat stone behind her, ending seated upright with her hands on her knees
keep: 0-5
generate: 6
source: pixellab
---
Alba, Ivo's late wife, in his flashbacks (STORY-05): red braid tied with a cornflower blue ribbon, freckles, cream linen dress, brown apron; an adult about 26 art px tall at 2x, facing east, feet on the frame's bottom row. Sitting down on the stone or the swing seat, a one-shot ending held (flashbacks 1, 3). Approved look: "Aprovar a arte" (user, 2026-11-11), the board tools/art/sources/story/alba_concept_codex.png; design docs/design/drafts/camada_pessoal.md ("Aprovar o rascunho", user, 2026-11-11). PixelLab animate-with-text-v3 from her standing still (frames in tools/art/sources/story/alba_sit/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/alba_sit alba_sit tools/art/sources/story/alba_standing_2x.png <out> --keep=0-5 --floor=61 --centre=10-40`.
Negative: outlines, black contour, front view, glow, text, ground, scenery
