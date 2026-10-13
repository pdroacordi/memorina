---
id: tiles_threshold_stone
command: tileset
target: res://assets/sprites/world/tilesets/threshold/stone.png
size: 128x960
frames: 1
source: procedural: tools/art/tiles/threshold_stone.json
seasons: 3
top_spring: see the recipe
top_autumn: see the recipe
top_winter: see the recipe
---
A look sheet of the `threshold` biome on the corner-Wang contract (architecture/biome-tilesets): 16 dual-grid tiles, the fill and four straight edges in variants, 2x density (16 art px per 32 px cell). Three season bands, spring (summer reads it) / autumn / winter top to bottom; one body, only the lip changes (grass or none / litter / snow), as the village does; the region's native band is winter.
Body: worn road slabs, two courses of 8 art px slabs offset by half, dusty joints #7a6a50, rounded worn corners; variants a crack, a wheel groove, a chip. Painted by `python -I tools/art/paint_tile_bodies.py tools/art/tiles/bodies/threshold_road.json tools/art/tiles/sources/threshold_road` (colours of the Codex sheet row 2).
`S` cells: Enums.Ground.STONE.
Composed by "<godot>" --headless --path . -s res://tools/art/assemble_tile_sheet.gd -- --recipe=res://tools/art/tiles/threshold_stone.json --out=res://assets/sprites/world/tilesets/threshold/stone.png. Reference: the approved board `tools/art/references/regions/board_threshold.png`. Approved board (2026-10-13): "Approve, fix the flat ground (Recommended)" - "Approve all six. In production: the Threshold and Orchard ground came out nearly flat beige, so give them texture (stones, roots, slabs) like our village earth; brighten the Frost Edge sea; make the woods trees less dense and the orchard windmills bigger." Tiles: "Own tiles per region (Recommended)"; "We should only our set of tiles from now on and not mix em."
