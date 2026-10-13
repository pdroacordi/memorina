---
id: tiles_lighthouse_stone
command: tileset
target: res://assets/sprites/world/tilesets/lighthouse/stone.png
size: 128x960
frames: 1
source: procedural: tools/art/tiles/lighthouse_stone.json
seasons: 3
top_spring: see the recipe
top_autumn: see the recipe
top_winter: see the recipe
---
A look sheet of the `lighthouse` biome on the corner-Wang contract (architecture/biome-tilesets): 16 dual-grid tiles, the fill and four straight edges in variants, 2x density (16 art px per 32 px cell). Three season bands, spring (summer reads it) / autumn / winter top to bottom; one body, only the lip changes (grass or none / litter / snow), as the village does; the region's native band is winter.
Body: white lighthouse masonry, two courses of 8 art px blocks offset by half, grey joints #a6a7a5; variants a chip, a stain, a crack. Painted by `python -I tools/art/paint_tile_bodies.py tools/art/tiles/bodies/lighthouse_masonry.json tools/art/tiles/sources/lighthouse_masonry` in the colours of the Codex masonry row (`tools/art/tiles/sources/frost_edge_tiles_codex_raw.png` row 2). "Lighthouse masonry tiles" (user, 2026-10-13): the lighthouse rooms get their own white masonry.
`S` cells: Enums.Ground.STONE; biome `lighthouse`.
Composed by "<godot>" --headless --path . -s res://tools/art/assemble_tile_sheet.gd -- --recipe=res://tools/art/tiles/lighthouse_stone.json --out=res://assets/sprites/world/tilesets/lighthouse/stone.png. Reference: the approved board `tools/art/references/regions/board_frost_edge.png`. Approved board (2026-10-13): "Approve, fix the flat ground (Recommended)" - "Approve all six. In production: the Threshold and Orchard ground came out nearly flat beige, so give them texture (stones, roots, slabs) like our village earth; brighten the Frost Edge sea; make the woods trees less dense and the orchard windmills bigger." Tiles: "Own tiles per region (Recommended)"; "We should only our set of tiles from now on and not mix em."
