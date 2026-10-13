---
id: tiles_lighthouse_wall
command: tileset
target: res://assets/sprites/world/tilesets/lighthouse/wall.png
size: 128x960
frames: 1
source: procedural: tools/art/tiles/lighthouse_wall.json
seasons: 1
top_spring: see the recipe
top_autumn: see the recipe
top_winter: see the recipe
---
A look sheet of the `lighthouse` biome on the corner-Wang contract (architecture/biome-tilesets): 16 dual-grid tiles, the fill and four straight edges in variants, 2x density (16 art px per 32 px cell). One band repeated three times (a back wall has no season).
The same masonry body as a back wall, one band (built walls stay one band, systems/seasonal-art); the `[back]` look of the `lighthouse` and `frost_edge` biomes.
Back wall: no collision, no ground.
Composed by "<godot>" --headless --path . -s res://tools/art/assemble_tile_sheet.gd -- --recipe=res://tools/art/tiles/lighthouse_wall.json --out=res://assets/sprites/world/tilesets/lighthouse/wall.png. Reference: the approved board `tools/art/references/regions/board_frost_edge.png`. Approved board (2026-10-13): "Approve, fix the flat ground (Recommended)" - "Approve all six. In production: the Threshold and Orchard ground came out nearly flat beige, so give them texture (stones, roots, slabs) like our village earth; brighten the Frost Edge sea; make the woods trees less dense and the orchard windmills bigger." Tiles: "Own tiles per region (Recommended)"; "We should only our set of tiles from now on and not mix em."
