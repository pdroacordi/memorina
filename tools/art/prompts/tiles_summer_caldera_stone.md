---
id: tiles_summer_caldera_stone
command: tileset
target: res://assets/sprites/world/tilesets/summer_caldera/stone.png
size: 128x960
frames: 1
source: procedural: tools/art/tiles/summer_caldera_stone.json
seasons: 3
top_spring: see the recipe
top_autumn: see the recipe
top_winter: see the recipe
---
A look sheet of the `summer_caldera` biome on the corner-Wang contract (architecture/biome-tilesets): 16 dual-grid tiles, the fill and four straight edges in variants, 2x density (16 art px per 32 px cell). Three season bands, spring (summer reads it) / autumn / winter top to bottom; one body, only the lip changes (grass or none / litter / snow), as the village does; the region's native band is summer (the spring band).
Body: porous basalt, three columnar blocks with dark cracks and six round pores (a dark pixel over a lit rim, so the pores survive at 16 art px, which the board lost); variants a pore cluster, a long crack, a sulphur fleck. Painted by `python -I tools/art/paint_tile_bodies.py tools/art/tiles/bodies/summer_caldera_basalt.json tools/art/tiles/sources/summer_caldera_basalt` (colours of `tools/art/tiles/sources/summer_caldera_tiles_codex_raw.png` row 1).
`S` cells: Enums.Ground.STONE. The Caldera has no earth ("No earth there", user, 2026-10-08).
Composed by "<godot>" --headless --path . -s res://tools/art/assemble_tile_sheet.gd -- --recipe=res://tools/art/tiles/summer_caldera_stone.json --out=res://assets/sprites/world/tilesets/summer_caldera/stone.png. Reference: the approved board `tools/art/references/regions/board_summer_caldera.png`. Approved board (2026-10-13): "Approve, fix the flat ground (Recommended)" - "Approve all six. In production: the Threshold and Orchard ground came out nearly flat beige, so give them texture (stones, roots, slabs) like our village earth; brighten the Frost Edge sea; make the woods trees less dense and the orchard windmills bigger." Tiles: "Own tiles per region (Recommended)"; "We should only our set of tiles from now on and not mix em."
