---
id: orchard_windmill_sails
command: generate
target: res://assets/sprites/world/props/wind_orchards/windmill_sails.png
size: 196x196
frames: 12
view: side
no_background: true
source: codex
---
Windmill sails, a set-dressing prop for the Wind Orchards (WORLD-16), seen straight on from the side, minimalist 16-bit, no outlines, flat colours. Cut from one Codex sheet (tools/art/sources/wind_orchards/orchard_built_codex.png, tools/art/sources/wind_orchards/orchard_nature_codex.png, tools/art/sources/wind_orchards/great_windmill_codex.png; tools/art/references/village_concept.png the only reference) by `python -I tools/art/cut_props.py <sheet> <dir> --figure=none --flat=9 --base-shade --colors=64 --names=... --size=...`. The great windmill's lattice sails cut at w92, squared and baked by `tools/art/bake_rotation.gd --frames=12 --period=90` (wrap ratio 0.98); 7.2 fps (0.15 turn/s) on the memory clock; the pivot is the small mill house's hub, 99 px over its base (the house cut at h85 after the WORLD-15..17 playtest: at h44 it read as a toy). Approved with the board docs/design/drafts/guardian_regions_dressing_board.md (user, 2026-11-20: "approved"; the sheets shown at game size before placing). Sized against Ivo's 29 art px (tools/art/region_prop_sizes.json, tools/art/interior_prop_sizes.json).
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, glow, blur, text, people
