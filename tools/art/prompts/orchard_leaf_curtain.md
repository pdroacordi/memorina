---
id: orchard_leaf_curtain
command: generate
target: res://assets/sprites/world/props/wind_orchards/leaf_curtain.png
size: 32x96
frames: 1
view: side
source: codex
---
A thick curtain of dry autumn leaves on thin dark vines, hanging from a stone lintel and closing a narrow passage, seen from the side: overlapping orange, ochre, rust and dull red leaves, nothing showing through, the lowest leaves hanging ragged. The `LeafCover`'s art (`leaf_cover.tscn`, drawn by region, so a taller cover repeats it): the curtain in orchard_leaf_path (col 14) that Soltar drops to open the side tunnel (design 02 section 8, Outono Espacial 1); the falling leaves are `wind_leaf.png`, in the same colours. It replaces the procedural leaf-wall tile the user asked about ("Another random rectangle", 2026-10-14; WORLD-36).
Drawn by Codex (one call, 2026-10-14; our orchard backdrop, the old leaf-wall tile and the wind leaf the only references), kept as tools/art/sources/wind_orchards/leaf_curtain_codex.png and cut by `python -I tools/art/cut_single_prop.py tools/art/sources/wind_orchards/leaf_curtain_codex.png assets/sprites/world/props/wind_orchards/leaf_curtain.png --width=16 --height=48 --parts --palette=assets/sprites/world/wind/wind_leaf.png,assets/sprites/world/tilesets/wind_orchards/earth.png,assets/sprites/world/props/wind_orchards/inn_facade.png,assets/sprites/world/background/wind_orchards/near.png,assets/sprites/world/background/wind_orchards/mid.png`: 16x48 art px at 2x.
Negative: outlines, black contour, perspective, tree trunk, sideways branches, ground, sky, scenery, text, green leaves
