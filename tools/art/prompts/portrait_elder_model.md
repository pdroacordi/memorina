---
id: portrait_elder_model
command: generate
target: res://assets/sprites/hud/portraits/elder_model.png
size: 96x76
frames: 1
view: side
direction: east
source: codex
---
The base of the elder's lighthouse model turned over, the patched flute carved on it: the dialogue portrait of the line where he sees the Memorina (05, Act 4). Minimalist 16-bit, no outlines, 2x density. Codex image generation, our own art the only reference; cut by `python -I tools/art/cut_single_prop.py tools/art/sources/story/story_cast_board_codex.png <out> --width=48 --palette= --box=1105,770,1290,915 --parts --flat=10`. Approved look: the story-cast board ("Aprovado. Só acho importante o visual do Ivo: ele deve ter um pouco mais de barba e o cabelo penteado para trás (quase que como um prince charming do shrek).", user, 2026-10-15) and script `docs/design/05_roteiro.md` ("Approve draft 2 (Recommended)", user, 2026-10-15).
Negative: outlines, black contour, text, frame, background, scenery, speckle, gradients, blur
