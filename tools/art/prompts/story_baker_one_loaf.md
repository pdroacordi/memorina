---
id: story_baker_one_loaf
command: generate
target: res://assets/sprites/world/story/baker/one_loaf.png
size: 30x52
frames: 1
view: side
direction: west
source: codex
---
The baker holding only the round loaf, the long one put back (05, 1c). Minimalist 16-bit, no outlines, 2x density. Codex image generation, our own art the only reference; cut by `python -I tools/art/cut_single_prop.py tools/art/sources/story/opening_poses_codex.png <out> --width=0 --height=26 --palette=assets/sprites/world/inhabitants/baker.png --box=495,425,720,790`. Approved look: the story-cast board ("Aprovado. Só acho importante o visual do Ivo: ele deve ter um pouco mais de barba e o cabelo penteado para trás (quase que como um prince charming do shrek).", user, 2026-10-15) and script `docs/design/05_roteiro.md` ("Approve draft 2 (Recommended)", user, 2026-10-15).
Negative: outlines, black contour, text, frame, background, scenery, speckle, gradients, blur
