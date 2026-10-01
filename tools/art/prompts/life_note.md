---
id: life_note
command: generate
target: res://assets/sprites/hud/life/life_note.png
size: 12x16
frames: 6
source: procedural: tools/art/draw_procedural_sprites.gd
---
Drawn by tools/art/draw_procedural_sprites.gd: a gold eighth note in the world palette with a dark outline, bobbing one pixel and flicking its flag up and back across six frames - one unit of Ivo's life (design 02, "Vida": a row of notes that lose their colour). Drawn in colour; `life_note.gdshader` takes the colour away pixel by pixel on the greyhush's Bayer cell when the unit is lost, and the HUD stops its clock there.
