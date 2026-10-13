---
id: tiles_frozen_lake_earth
command: tileset
target: res://assets/sprites/world/tilesets/frozen_lake/earth.png
size: 128x960
frames: 1
source: procedural: tools/art/tiles/frozen_lake_earth.json
seasons: 3
top_spring: see the recipe
top_autumn: see the recipe
top_winter: see the recipe
---
A look sheet of the `frozen_lake` biome on the corner-Wang contract (architecture/biome-tilesets): 16 dual-grid tiles, the fill and four straight edges in variants, the ledge strip, 2x density (16 art px per 32 px cell). Three season bands, spring (summer reads it) / autumn / winter top to bottom; one body, only the lip changes (grass or none / litter / snow), as the village does; the region's native band is winter.
Body: cold dark chasm earth with grey pebbles, Codex (`tools/art/tiles/sources/frozen_lake_tiles_codex_raw.png` row 2), quilted seamless by `python -I tools/art/cut_tile_bodies.py tools/art/tiles/sources/frozen_lake_tiles_codex_raw.png 1 tools/art/tiles/sources/frozen_lake_earth --colors=6 --contrast=0.7`.
`#` and `=` cells: Enums.Ground.EARTH.
Composed by "<godot>" --headless --path . -s res://tools/art/assemble_tile_sheet.gd -- --recipe=res://tools/art/tiles/frozen_lake_earth.json --out=res://assets/sprites/world/tilesets/frozen_lake/earth.png. Reference: the approved board `tools/art/references/regions/board_frozen_lake.png`. Approved board (2026-10-13): "Approve, fix the flat ground (Recommended)" - "Approve all six. In production: the Threshold and Orchard ground came out nearly flat beige, so give them texture (stones, roots, slabs) like our village earth; brighten the Frost Edge sea; make the woods trees less dense and the orchard windmills bigger." Tiles: "Own tiles per region (Recommended)"; "We should only our set of tiles from now on and not mix em."
