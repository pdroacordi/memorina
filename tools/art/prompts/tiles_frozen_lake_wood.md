---
id: tiles_frozen_lake_wood
command: tileset
target: res://assets/sprites/world/tilesets/frozen_lake/wood.png
size: 128x960
frames: 1
source: procedural: tools/art/tiles/frozen_lake_wood.json
seasons: 3
top_spring: see the recipe
top_autumn: see the recipe
top_winter: see the recipe
---
A look sheet of the `frozen_lake` biome on the corner-Wang contract (architecture/biome-tilesets): 16 dual-grid tiles, the fill and four straight edges in variants, the ledge strip, 2x density (16 art px per 32 px cell). Three season bands, spring (summer reads it) / autumn / winter top to bottom; one body, only the lip changes (grass or none / litter / snow), as the village does; the region's native band is winter.
Body: grey weathered stilt planks: our village planks (`tools/art/tiles/sources/village_planks_*.png`) recoloured by `python -I tools/art/cut_tile_bodies.py tools/art/tiles/sources/frozen_lake_planks --recolour=tools/art/tiles/sources/village_planks --ramp=#2e2c2a,#4a4640,#5e5a52,#6e6a60,#7e786c,#8e887a` (the board's Codex planks did not tile, 1.8-2.4; the board README proposed this recolour).
`%` and `-` cells: Enums.Ground.WOOD.
Composed by "<godot>" --headless --path . -s res://tools/art/assemble_tile_sheet.gd -- --recipe=res://tools/art/tiles/frozen_lake_wood.json --out=res://assets/sprites/world/tilesets/frozen_lake/wood.png. Reference: the approved board `tools/art/references/regions/board_frozen_lake.png`. Approved board (2026-10-13): "Approve, fix the flat ground (Recommended)" - "Approve all six. In production: the Threshold and Orchard ground came out nearly flat beige, so give them texture (stones, roots, slabs) like our village earth; brighten the Frost Edge sea; make the woods trees less dense and the orchard windmills bigger." Tiles: "Own tiles per region (Recommended)"; "We should only our set of tiles from now on and not mix em."
