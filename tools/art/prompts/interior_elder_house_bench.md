---
id: interior_elder_house_bench
command: generate
target: res://assets/sprites/world/props/interiors/elder_house/bench.png
size: 48x18
frames: 1
view: side
direction: west
source: codex
---
A low wooden bench where the two children sit for the elder's story (05, 1e). Minimalist 16-bit, no outlines, 2x density. Codex image generation, our own art the only reference; cut by `python -I tools/art/cut_single_prop.py tools/art/sources/story/opening_poses_codex.png <out> --width=24 --palette=assets/sprites/world/props/interiors/elder_house/stool.png,assets/sprites/world/props/interiors/ivo_house/chair.png --box=1500,250,1815,380`. Approved look: the story-cast board ("Aprovado. Só acho importante o visual do Ivo: ele deve ter um pouco mais de barba e o cabelo penteado para trás (quase que como um prince charming do shrek).", user, 2026-10-15) and script `docs/design/05_roteiro.md` ("Approve draft 2 (Recommended)", user, 2026-10-15).
Negative: outlines, black contour, text, frame, background, scenery, speckle, gradients, blur
