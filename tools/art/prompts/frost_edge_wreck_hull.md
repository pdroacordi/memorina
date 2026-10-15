---
id: frost_edge_wreck_hull
command: generate
target: res://assets/sprites/world/props/frost_edge/wreck_hull.png
size: 624x188
frames: 1
view: side
source: codex
---
An old wooden shipwreck beached and half sunk in frozen sand, seen broadside: a long low curved hull of dark tarred horizontal planks, the bow rising at the right end, a broken mast stump and snapped ribs at the top, snow along the gunwale and in the seams, icicles; one ragged dark breach in the hull at ground level. The front of the wreck on frost_shore that holds the door to frost_wreck_hold (WORLD-35 step 6; design 04 §3.3 names the wreck), so the door stands in a ship, not alone on the beach ("doorways fit their place", features/doorways-fit-their-place). Measured: the breach's centre is about 302 px from the left edge and the breach about 48 px tall from the ground line, so the door's art sits in it; the bottom edge is the ground line. Anchor: the bottom left corner.
Drawn by Codex (one call, 2026-10-15; our fisher's hut front and the Frost Edge stone tiles the only references), kept as tools/art/sources/frost_edge/wreck_hull_codex.png and cut by `python -I tools/art/cut_single_prop.py tools/art/sources/frost_edge/wreck_hull_codex.png assets/sprites/world/props/frost_edge/wreck_hull.png --width=312 --parts --colors=12 --palette=assets/sprites/world/props/frozen_lake/fisher_hut_facade.png,assets/sprites/world/tilesets/frost_edge/stone.png`: 312 art px wide at 2x, sized so the breach is about Ivo's height.
Negative: outlines, black contour, perspective, sails, water, waves, sky, scenery, people, text, lit windows
