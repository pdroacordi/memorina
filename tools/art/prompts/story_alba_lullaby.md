---
id: story_alba_lullaby
command: animate3
target: res://assets/sprites/world/story/alba/lullaby.png
size: 96x64
frames: 8
view: side
direction: east
reference: res://tools/art/sources/story/alba_lullaby_2x.png
action: seated on the ground, a woman rocks very slowly, singing softly with her eyes on the sleeping child curled up beside her under a quilt, her hand stroking the child's hair; the child stays asleep and still
keep: 0-4,3-1
generate: 8
source: pixellab
---
Alba seated on the ground under the old tree with the daughter asleep curled up beside her under a patchwork quilt, her head on her mother's knee (flashback 5, the lullaby), a loop. The still is a Codex redraw of the board's lap pose (tools/art/sources/story/alba_lullaby_codex.png; a prompt with the girl "lying across the lap" was refused by Codex's moderation), cut by `python -I tools/art/cut_single_prop.py tools/art/sources/story/alba_lullaby_codex.png tools/art/sources/story/alba_lullaby_cut.png --width=0 --height=20 --flat=20` and padded by `python -I tools/art/pad_reference.py tools/art/sources/story/alba_lullaby_cut.png tools/art/sources/story/alba_lullaby_2x.png 96x64`. Approved look: "Aprovar a arte" (user, 2026-11-11), the board tools/art/sources/story/alba_concept_codex.png; design docs/design/drafts/camada_pessoal.md ("Aprovar o rascunho", user, 2026-11-11). Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/alba_lullaby alba_lullaby tools/art/sources/story/alba_lullaby_2x.png <out> --keep=0-4,3-1 --floor=61`.
Negative: outlines, black contour, front view, glow, text, ground, scenery
