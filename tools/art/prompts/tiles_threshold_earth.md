---
id: tiles_threshold_earth
command: tileset
target: res://assets/sprites/world/tilesets/threshold/earth.png
size: 128x960
frames: 1
source: procedural: tools/art/tiles/threshold_earth.json
seasons: 3
top_spring: see the recipe
top_autumn: see the recipe
top_winter: see the recipe
---
A look sheet of the `threshold` biome on the corner-Wang contract (architecture/biome-tilesets): 16 dual-grid tiles, the fill and four straight edges in variants, the ledge strip, 2x density (16 art px per 32 px cell). Three season bands, spring (summer reads it) / autumn / winter top to bottom; one body, only the lip changes (grass or none / litter / snow), as the village does; the region's native band is winter.
Body: dry pale earth, a calm three-tone mottle and four detail variants (a stone, a forked root, three pebbles, a second stone), painted by `python -I tools/art/paint_tile_bodies.py tools/art/tiles/bodies/threshold_earth.json tools/art/tiles/sources/threshold_earth` in the colours of the Codex sheet `tools/art/tiles/sources/threshold_tiles_codex_raw.png` row 1 (measured: base #977d58..#c7a677 in the raw, set one value step darker, #83694c..#9c815b, for contrast against the pale winter backdrop as on the board). The Codex tiles came back at about 32 art px; shrunk to 16 they turned to speckle, so the body is painted at 16 art px.
`#` cells: Enums.Ground.EARTH (roots take it).
Composed by "<godot>" --headless --path . -s res://tools/art/assemble_tile_sheet.gd -- --recipe=res://tools/art/tiles/threshold_earth.json --out=res://assets/sprites/world/tilesets/threshold/earth.png. Reference: the approved board `tools/art/references/regions/board_threshold.png`. Approved board (2026-10-13): "Approve, fix the flat ground (Recommended)" - "Approve all six. In production: the Threshold and Orchard ground came out nearly flat beige, so give them texture (stones, roots, slabs) like our village earth; brighten the Frost Edge sea; make the woods trees less dense and the orchard windmills bigger." Tiles: "Own tiles per region (Recommended)"; "We should only our set of tiles from now on and not mix em."
