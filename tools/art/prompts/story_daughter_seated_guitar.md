---
id: story_daughter_seated_guitar
command: generate
target: res://assets/sprites/world/story/daughter/seated_guitar.png
size: 36x40
frames: 1
view: side
direction: east
source: codex
---
The daughter on a stool with the guitar on her lap, trying the song herself (05, Act 4, HOLD). Minimalist 16-bit, no outlines, 2x density. Codex image generation, our own art the only reference; cut by `python -I tools/art/cut_single_prop.py tools/art/sources/story/opening_poses_codex.png <out> --width=0 --height=20 --palette=$(ls assets/sprites/world/inhabitants/*.png | tr '\n' ','),assets/sprites/characters/ivo/ivo_idle.png --box=375,120,630,395`. Approved look: the story-cast board ("Aprovado. Só acho importante o visual do Ivo: ele deve ter um pouco mais de barba e o cabelo penteado para trás (quase que como um prince charming do shrek).", user, 2026-10-15) and script `docs/design/05_roteiro.md` ("Approve draft 2 (Recommended)", user, 2026-10-15).
Negative: outlines, black contour, text, frame, background, scenery, speckle, gradients, blur
