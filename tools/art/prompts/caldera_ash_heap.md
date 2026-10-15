---
id: caldera_ash_heap
command: generate
target: res://assets/sprites/world/props/summer_caldera/ash_heap.png
size: 128x32
frames: 1
view: side
source: codex
---
A deep, soft heap of fine grey volcanic ash at the foot of a basalt shaft, seen from the side: a wide low mound of pale and mid grey ash with a rounded top and sloping ends, a few small dark cinders half buried. The prop over the soft-landing zone at the bottom of caldera_sun_stair's straight gap (WORLD-35 step 5), so the long fall reads as landing in ash; the orchestrator's call following the user's icefall decision ("Straight drop into deep snow (Recommended)", 2026-10-15). Art only: the zone, not the prop, cancels the hard landing; a prop never collides.
Drawn by Codex (one call, 2026-10-15; our snow drift for the shape, the Summer Caldera ash and basalt tiles for the colours the only references), kept as tools/art/sources/summer_caldera/ash_heap_codex.png and cut by `python -I tools/art/cut_single_prop.py tools/art/sources/summer_caldera/ash_heap_codex.png assets/sprites/world/props/summer_caldera/ash_heap.png --width=64 --height=16 --parts --colors=5 --palette=assets/sprites/world/tilesets/summer_caldera/ash.png,assets/sprites/world/tilesets/summer_caldera/stone.png`: 64x16 art px at 2x. Anchor: the bottom centre, 64,32.
Negative: outlines, black contour, perspective, smoke, fire, lava, glow, rocks, ground, sky, scenery, text
