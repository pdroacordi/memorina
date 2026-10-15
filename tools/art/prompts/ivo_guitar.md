---
id: ivo_guitar
command: generate
target: res://assets/sprites/characters/ivo/ivo_guitar.png
size: 128x128
frames: 2
view: side
direction: east
source: codex
---
Ivo holding his guitar in playing position: frame 1 at rest (`guitar_hold`), frame 2 strumming (`guitar_strum`), facing east, the head column on x 64 and the feet on row 96 as in ivo_idle. Minimalist 16-bit, no outlines, 2x density. Codex image generation, our own art the only reference; cut by two poses cut by `python -I tools/art/cut_single_prop.py tools/art/sources/story/opening_poses_codex.png <out> --width=0 --height=29 --palette=assets/sprites/characters/ivo/ivo_idle.png,assets/sprites/world/props/interiors/ivo_house/guitar.png --box=870,410,1145,790` (and `--box=1235,410,1510,790`), each pasted on a 128x128 frame. Approved look: the story-cast board ("Aprovado. Só acho importante o visual do Ivo: ele deve ter um pouco mais de barba e o cabelo penteado para trás (quase que como um prince charming do shrek).", user, 2026-10-15) and script `docs/design/05_roteiro.md` ("Approve draft 2 (Recommended)", user, 2026-10-15).
Negative: outlines, black contour, text, frame, background, scenery, speckle, gradients, blur
