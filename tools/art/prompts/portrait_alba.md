---
id: portrait_alba
command: generate
target: res://assets/sprites/hud/portraits/alba.png
size: 84x96
frames: 1
view: side
direction: east
source: codex
---
Alba: copper-red hair in a loose braid tied with a cornflower blue ribbon, freckles, cream linen dress and brown apron, a faint smile. A dialogue portrait (STORY-05, `systems/dialogue`): a head-and-shoulders bust facing right, 48 art px tall at 2x, shown in the box's 48x48 portrait slot. Approved look: "Aprovar a arte" (user, 2026-11-11), the board tools/art/sources/story/alba_concept_codex.png; design docs/design/drafts/camada_pessoal.md ("Aprovar o rascunho", user, 2026-11-11). Cut from the board's bust by `python -I tools/art/cut_single_prop.py tools/art/sources/story/alba_concept_codex.png assets/sprites/hud/portraits/alba.png --width=0 --height=48 --box=30,40,330,375 --flat=16`; the ribbon colour (110,111,128) the flatten greys restored to (118,152,199); then padded on the left to a width that is a multiple of 4 (`gotchas/a-centred-texture-rect-can-land-half-an-art-pixel-off-the-grid`).
Negative: outlines, black contour, text, frame, background, speckle, gradients
