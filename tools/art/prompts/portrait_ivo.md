---
id: portrait_ivo
command: generate
target: res://assets/sprites/hud/portraits/ivo.png
size: 92x96
frames: 1
view: side
direction: east
source: codex
---
Ivo: tired eyes, a short full beard, brown hair combed back, the blue scarf and cream shirt; redrawn on its own from the board's bust (tools/art/sources/story/ivo_portrait_codex.png). A dialogue portrait (STORY-08, `systems/dialogue`): a head-and-shoulders bust facing right, 48 art px tall at 2x, shown in the box's 48x48 portrait slot. Cut from the approved story-cast board ("Aprovado. Só acho importante o visual do Ivo: ele deve ter um pouco mais de barba e o cabelo penteado para trás (quase que como um prince charming do shrek).", user, 2026-10-15) by `python -I tools/art/cut_single_prop.py tools/art/sources/story/ivo_portrait_codex.png assets/sprites/hud/portraits/ivo.png --width=0 --height=48 --palette=$(ls assets/sprites/world/inhabitants/*.png | tr '\n' ','),assets/sprites/characters/ivo/ivo_idle.png`.
Negative: outlines, black contour, text, frame, background, speckle, gradients
