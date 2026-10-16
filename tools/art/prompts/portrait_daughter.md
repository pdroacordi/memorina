---
id: portrait_daughter
command: generate
target: res://assets/sprites/hud/portraits/daughter.png
size: 72x96
frames: 1
view: side
direction: east
source: codex
---
Ivo's daughter, about 10: brown hair in one long braid, cream blouse, faded green pinafore, a serious, quiet face. A dialogue portrait (STORY-08, `systems/dialogue`): a head-and-shoulders bust facing right, 48 art px tall at 2x, shown in the box's 48x48 portrait slot. Cut from the approved story-cast board ("Aprovado. Só acho importante o visual do Ivo: ele deve ter um pouco mais de barba e o cabelo penteado para trás (quase que como um prince charming do shrek).", user, 2026-10-15) by `python -I tools/art/cut_single_prop.py tools/art/sources/story/story_cast_board_codex.png assets/sprites/hud/portraits/daughter.png --width=0 --height=48 --box=380,30,620,380 --palette=$(ls assets/sprites/world/inhabitants/*.png | tr '\n' ','),assets/sprites/characters/ivo/ivo_idle.png`. Then padded with one transparent art-px column on the left, so the width is a multiple of 4 and the centred slot lands on the 2x grid (`gotchas/a-centred-texture-rect-can-land-half-an-art-pixel-off-the-grid`).
Negative: outlines, black contour, text, frame, background, speckle, gradients
