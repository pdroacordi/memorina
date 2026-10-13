---
id: tiles_summer_caldera_wall
command: tileset
target: res://assets/sprites/world/tilesets/summer_caldera/wall.png
size: 128x960
frames: 1
source: procedural: tools/art/tiles/summer_caldera_wall.json
seasons: 1
top_spring: see the recipe
top_autumn: see the recipe
top_winter: see the recipe
---
A look sheet of the `summer_caldera` biome on the corner-Wang contract (architecture/biome-tilesets): 16 dual-grid tiles, the fill and four straight edges in variants, 2x density (16 art px per 32 px cell). One band repeated three times (a back wall has no season).
Body: temple sandstone, two courses of 16 art px ashlar blocks offset by half, thin joints #8a6c44; variants a chip, a carved line, a stain. Painted by `python -I tools/art/paint_tile_bodies.py tools/art/tiles/bodies/summer_caldera_sandstone.json tools/art/tiles/sources/summer_caldera_sandstone` (colours of the Codex sheet row 2). A back wall, one band, for both caldera biomes (the temple's walls, GRD-04).
Back wall: no collision, no ground.
Composed by "<godot>" --headless --path . -s res://tools/art/assemble_tile_sheet.gd -- --recipe=res://tools/art/tiles/summer_caldera_wall.json --out=res://assets/sprites/world/tilesets/summer_caldera/wall.png. Reference: the approved board `tools/art/references/regions/board_summer_caldera.png`. Approved board (2026-10-13): "Approve, fix the flat ground (Recommended)" - "Approve all six. In production: the Threshold and Orchard ground came out nearly flat beige, so give them texture (stones, roots, slabs) like our village earth; brighten the Frost Edge sea; make the woods trees less dense and the orchard windmills bigger." Tiles: "Own tiles per region (Recommended)"; "We should only our set of tiles from now on and not mix em."
