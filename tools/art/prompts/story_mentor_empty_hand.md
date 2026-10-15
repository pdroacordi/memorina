---
id: story_mentor_empty_hand
command: generate
target: res://assets/sprites/world/story/mentor/empty_hand.png
size: 86x120
frames: 1
view: side
direction: west
source: codex
---
The mentor standing, his raised hand empty, 60 art px; the Memorina he holds out is the separate `memorina_in_hand` sprite, so the gift only removes it (05, Act 3). Minimalist 16-bit, no outlines, 2x density. Codex image generation, our own art the only reference; cut by `python -I tools/art/cut_single_prop.py tools/art/sources/story/mentor_empty_hand_codex.png <out> --width=0 --height=60 --palette= --parts --flat=12` (a Codex redraw of the board's mentor with the flute painted out). Approved look: the story-cast board ("Aprovado. Só acho importante o visual do Ivo: ele deve ter um pouco mais de barba e o cabelo penteado para trás (quase que como um prince charming do shrek).", user, 2026-10-15) and script `docs/design/05_roteiro.md` ("Approve draft 2 (Recommended)", user, 2026-10-15).
Negative: outlines, black contour, text, frame, background, scenery, speckle, gradients, blur
