---
id: frozen_lake_snow_drift
command: generate
target: res://assets/sprites/world/props/frozen_lake/snow_drift.png
size: 128x32
frames: 1
view: side
source: codex
---
A deep, soft drift of fresh snow at the foot of a cliff, seen from the side: a wide low mound with a rounded top and sloping ends, pale snow in close values, soft hollows and two small chunks of ice half buried. The prop over the soft-landing zone at the bottom of the icefall shaft (WORLD-35 step 3), so the long drop reads as landing in snow: "Straight drop into deep snow (Recommended)": "One long drop down the shaft that lands in a drift of deep snow at the bottom, which breaks the fall: no stun, about 2 s. Needs a small 'soft landing' rule (a snow/water cell that cancels the hard landing)." (user, 2026-10-15). Art only: the zone, not the prop, cancels the hard landing; a prop never collides.
Drawn by Codex (one call, 2026-10-15; our frozen_lake stone tiles, threshold earth tiles and the border cairn the only references), kept as tools/art/sources/frozen_lake/snow_drift_codex.png and cut by `python -I tools/art/cut_single_prop.py tools/art/sources/frozen_lake/snow_drift_codex.png assets/sprites/world/props/frozen_lake/snow_drift.png --width=64 --height=16 --parts --colors=5 --palette=assets/sprites/world/tilesets/frozen_lake/stone.png,assets/sprites/world/props/frozen_lake/border_cairn.png,assets/sprites/world/tilesets/lighthouse/stone.png`: 64x16 art px at 2x (stretched about 1.4 times in height so the drift reads deep). Anchor: the bottom centre, 64,32.
Negative: outlines, black contour, perspective, rocks, trees, ground, sky, scenery, text, footprints
