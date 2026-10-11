---
id: helix_look_bell_tower
command: generate
target: res://assets/sprites/world/props/helix_stair/bell_tower_bell.png
size: 46x54
frames: 1
view: side
source: codex
---
The bell tower's HelixLook (`resources/world/helix/bell_tower_look.tres`, read only by `HelixView`; systems/helix-stair): a palette and dimension contract for the turning tower, which is drawn as flat-shaded geometry, never as an image. Sampled from the approved board tools/art/sources/bell_tower_board_codex.png (Codex, our own references only; "Approve (Recommended)", user, 2026-10-11): wall stone #766954, #80725d, #8f7f67, mortar #554b42, highlight #99886c, shadow #5d5448; timber #714f38, #4e3f35, line #2c211c; tread #946340, #805538, nosing #9b673f; riser #553d2c, #453125; soffit #3d3028, #34271f; stringer #805538, #6b482f, #312724; slit glass #a7d5f8, #677581, frame #27252a; floor #9c8c73, #b09e7b, line #6e685e. Wall courses 24 px, blocks 40-64 px along the wall; steps 20 px thick; slits 16 x 56 px at six (angle, height) places; two posts 12 px wide; one beam 16 px high under the roof. The only image is the bell (this target): the board's iron bell, hung on the axis, cut at its axis-depth size (x0.87 of the board scale) by `python -I tools/art/cut_board_prop.py tools/art/sources/bell_tower_board_codex.png assets/sprites/world/props/helix_stair/bell_tower_bell.png --box=294,58,390,190 --art-per-px=0.235 --colors=10 --luma=62`: what is dark or not warm against the ochre wall, mortar opened away, 2x density, 10 colours. The user approves a still at phi 0, a quarter turn and the head before tuning (architecture/walkable-helix-stair, Revision).
Negative: outlines, perspective, glow, cast shadows, wall, beams, text
