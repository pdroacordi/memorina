---
id: orchard_leaf_pile
command: generate
target: res://assets/sprites/world/props/wind_orchards/leaf_pile.png
size: 128x32
frames: 1
view: side
source: codex
---
A deep, soft heap of fallen dry autumn leaves at the foot of a cliff, seen from the side: a wide low mound of orange, ochre, rust and dull red leaves with a rounded top and sloping ends. The prop over the soft-landing zones at the foot of the Wind Orchards' two long drops back (orchard_ridge to the leaf path, orchard_summit to the terraces; WORLD-35 step 4), so the drop reads as landing in leaves; the orchestrator's call following the user's icefall decision ("Straight drop into deep snow (Recommended)", 2026-10-15). Art only: the zone, not the prop, cancels the hard landing; a prop never collides.
Drawn by Codex (one call, 2026-10-15; our snow drift for the shape, the leaf curtain and the orchard earth tiles for the colours the only references), kept as tools/art/sources/wind_orchards/leaf_pile_codex.png and cut by `python -I tools/art/cut_single_prop.py tools/art/sources/wind_orchards/leaf_pile_codex.png assets/sprites/world/props/wind_orchards/leaf_pile.png --width=64 --height=16 --parts --colors=5 --palette=assets/sprites/world/props/wind_orchards/leaf_curtain.png,assets/sprites/world/wind/wind_leaf.png,assets/sprites/world/tilesets/wind_orchards/earth.png`: 64x16 art px at 2x. Anchor: the bottom centre, 64,32.
Negative: outlines, black contour, perspective, branches, trunks, rocks, ground, sky, scenery, text, green leaves
