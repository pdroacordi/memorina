---
id: input_key_blank
command: generate
target: res://assets/sprites/hud/memorina/input_key_blank_normal.png
size: 16x16
frames: 1
source: procedural: tools/art/draw_input_key_blank.py
---
The note key a rebound note is drawn with when its input has no note glyph (UI-07, systems/settings): the W note key (`input_key_w_normal.png`, `input_key_w_selected.png`, Franuka's RPG UI pack) with its letter cleared. The letter's pixels (x 5-9, y 5-9 of 16) take the face's own values: the top row (163, 167, 194), the rest (104, 111, 153); outline, shadow and the selected state's gold ring stay. The HUD writes the binding's name over it. Drawn by `python -I tools/art/draw_input_key_blank.py assets/sprites/hud/memorina`. No image was generated or uploaded.
Negative: new outline, glow, text baked in
