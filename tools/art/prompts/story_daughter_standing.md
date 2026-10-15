---
id: story_daughter_standing
command: generate
target: res://assets/sprites/world/story/daughter/standing.png
size: 14x44
frames: 1
view: side
direction: west
source: codex
---
Ivo's daughter standing, facing left, 22 art px (STORY-03). Minimalist 16-bit, no outlines, 2x density. Codex image generation, our own art the only reference; cut by `python -I tools/art/cut_single_prop.py tools/art/sources/story/story_cast_board_codex.png <out> --width=0 --height=22 --palette=$(ls assets/sprites/world/inhabitants/*.png | tr '\n' ','),assets/sprites/characters/ivo/ivo_idle.png --box=400,540,580,925`. Approved look: the story-cast board ("Aprovado. Só acho importante o visual do Ivo: ele deve ter um pouco mais de barba e o cabelo penteado para trás (quase que como um prince charming do shrek).", user, 2026-10-15) and script `docs/design/05_roteiro.md` ("Approve draft 2 (Recommended)", user, 2026-10-15).
Negative: outlines, black contour, text, frame, background, scenery, speckle, gradients, blur
