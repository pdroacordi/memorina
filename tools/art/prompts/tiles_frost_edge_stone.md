---
id: tiles_frost_edge_stone
command: tileset
target: res://assets/sprites/world/tilesets/frost_edge/stone.png
size: 128x960
frames: 1
source: procedural: tools/art/tiles/frost_edge_stone.json
seasons: 3
top_spring: see the recipe
top_autumn: see the recipe
top_winter: see the recipe
---
A look sheet of the `frost_edge` biome on the corner-Wang contract (architecture/biome-tilesets): 16 dual-grid tiles, the fill and four straight edges in variants, 2x density (16 art px per 32 px cell). Three season bands, spring (summer reads it) / autumn / winter top to bottom; one body, only the lip changes (grass or none / litter / snow), as the village does; the region's native band is winter.
Body: the shared natural rock, Codex (`tools/art/tiles/sources/frost_edge_tiles_codex_raw.png` row 1), quilted seamless by `python -I tools/art/cut_tile_bodies.py tools/art/tiles/sources/frost_edge_tiles_codex_raw.png 0 tools/art/tiles/sources/frost_edge_rock --colors=6 --saturation=0.4 --value=0.82` (the board's retone: saturation 0.4, value 0.82, dark slate). "One rock, two palettes (Recommended)" (user, 2026-10-13): the lake stone is this body recoloured.
`S` cells: Enums.Ground.STONE. The Frost Edge has no earth ("No earth there", user, 2026-10-08).
Composed by "<godot>" --headless --path . -s res://tools/art/assemble_tile_sheet.gd -- --recipe=res://tools/art/tiles/frost_edge_stone.json --out=res://assets/sprites/world/tilesets/frost_edge/stone.png. Reference: the approved board `tools/art/references/regions/board_frost_edge.png`. Approved board (2026-10-13): "Approve, fix the flat ground (Recommended)" - "Approve all six. In production: the Threshold and Orchard ground came out nearly flat beige, so give them texture (stones, roots, slabs) like our village earth; brighten the Frost Edge sea; make the woods trees less dense and the orchard windmills bigger." Tiles: "Own tiles per region (Recommended)"; "We should only our set of tiles from now on and not mix em."
