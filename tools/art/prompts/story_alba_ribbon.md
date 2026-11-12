---
id: story_alba_ribbon
command: animate3
target: res://assets/sprites/world/story/alba/ribbon.png
size: 64x64
frames: 9
view: side
direction: east
reference: res://tools/art/sources/story/alba_standing_2x.png
action: reaches up and unties a blue ribbon from her braid, then holds it out in front of her with both hands as if tying it around someone's wrist
keep: 0-8
generate: 8
source: pixellab
---
Alba, Ivo's late wife, in his flashbacks (STORY-05): red braid tied with a cornflower blue ribbon, freckles, cream linen dress, brown apron; an adult about 26 art px tall at 2x, facing east, feet on the frame's bottom row. Untying the ribbon and tying it on Ivo's wrist, a one-shot (flashback 4); his wrist is not in the frame. Approved look: "Aprovar a arte" (user, 2026-11-11), the board tools/art/sources/story/alba_concept_codex.png; design docs/design/drafts/camada_pessoal.md ("Aprovar o rascunho", user, 2026-11-11). PixelLab animate-with-text-v3 from her standing still (frames in tools/art/sources/story/alba_ribbon/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/alba_ribbon alba_ribbon tools/art/sources/story/alba_standing_2x.png <out> --keep=0-8 --floor=61 --centre=10-40`.
Negative: outlines, black contour, front view, glow, text, ground, scenery
