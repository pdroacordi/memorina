---
id: story_alba_standing
command: animate3
target: res://assets/sprites/world/story/alba/standing.png
size: 64x64
frames: 6
view: side
direction: east
reference: res://tools/art/sources/story/alba_standing_2x.png
action: idle: a young woman standing quietly, hands loosely together, humming softly with her eyes half closed, breathing slowly, her braid swaying a little; feet stay planted
keep: 0-3,2-1
generate: 8
source: pixellab
---
Alba, Ivo's late wife, in his flashbacks (STORY-05): red braid tied with a cornflower blue ribbon, freckles, cream linen dress, brown apron; an adult about 26 art px tall at 2x, facing east, feet on the frame's bottom row. Her idle loop, humming (flashbacks 1-5). The still is the board's standing figure redrawn by Codex on the daughter's pixel grid (tools/art/sources/story/alba_standing_codex.png), cut by `python -I tools/art/cut_single_prop.py tools/art/sources/story/alba_standing_codex.png tools/art/sources/story/alba_standing_cut.png --width=0 --height=26 --flat=14`, the ribbon colour (190,168,155) the flatten greys restored to (118,152,199), and padded by `python -I tools/art/pad_reference.py tools/art/sources/story/alba_standing_cut.png tools/art/sources/story/alba_standing_2x.png 64x64`. Approved look: "Aprovar a arte" (user, 2026-11-11), the board tools/art/sources/story/alba_concept_codex.png; design docs/design/drafts/camada_pessoal.md ("Aprovar o rascunho", user, 2026-11-11). PixelLab animate-with-text-v3 from her standing still (frames in tools/art/sources/story/alba_standing/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/alba_standing alba_standing tools/art/sources/story/alba_standing_2x.png <out> --keep=0-3,2-1 --floor=61 --centre=10-40`.
Negative: outlines, black contour, front view, glow, text, ground, scenery
