---
id: tiles_threshold_crack
command: generate
target: res://assets/sprites/world/tilesets/threshold/crack.png
size: 128x96
frames: 1
source: procedural: tools/art/draw_cracks.gd
---
Hairline crack decals a cracked secret cell of the `threshold` biome draws over its closed stone (architecture/secret-false-walls, "Hints"): 4 variants across, the same in each of the 3 season bands, 1 art px wide, 6-11 art px long, at least 3 art px from every cell edge, in the road slabs' joint colour. Drawn by `"<godot>" --headless --path . -s res://tools/art/draw_cracks.gd -- --out=res://assets/sprites/world/tilesets/threshold/crack.png --color=#5e5038 --scale=2 --seed=7`. Reference: `tools/art/references/regions/board_threshold.png`.
