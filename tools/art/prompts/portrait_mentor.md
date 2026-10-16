---
id: portrait_mentor
command: generate
target: res://assets/sprites/hud/portraits/mentor.png
size: 88x96
frames: 1
view: side
direction: east
source: codex
---
The mentor, lucid: the winter guardian of the lighthouse, a hood of grey-green lichen and small icicles, a smooth pale wooden mask with two dark knots for eyes and no mouth; its own colours (no prop has them yet), flattened to 10. A dialogue portrait (STORY-08, `systems/dialogue`): a head-and-shoulders bust facing right, 48 art px tall at 2x, shown in the box's 48x48 portrait slot. Cut from the approved story-cast board ("Aprovado. Só acho importante o visual do Ivo: ele deve ter um pouco mais de barba e o cabelo penteado para trás (quase que como um prince charming do shrek).", user, 2026-10-15) by `python -I tools/art/cut_single_prop.py tools/art/sources/story/story_cast_board_codex.png assets/sprites/hud/portraits/mentor.png --width=0 --height=48 --box=995,30,1320,380 --parts --palette= --flat=10`. Then padded with one transparent art-px column on the left, so the width is a multiple of 4 and the centred slot lands on the 2x grid (`gotchas/a-centred-texture-rect-can-land-half-an-art-pixel-off-the-grid`).
Negative: outlines, black contour, text, frame, background, speckle, gradients
