---
id: orchard_great_windmill_sails
command: generate
target: res://assets/sprites/world/props/wind_orchards/great_windmill_sails.png
size: 248x248
frames: 12
view: side
no_background: true
source: codex
---
Great windmill sails, a set-dressing prop for the Wind Orchards (WORLD-16), seen straight on from the side, minimalist 16-bit, no outlines, flat colours. Cut from one Codex sheet (tools/art/sources/wind_orchards/orchard_built_codex.png, tools/art/sources/wind_orchards/orchard_nature_codex.png, tools/art/sources/wind_orchards/great_windmill_codex.png; tools/art/references/village_concept.png the only reference) by `python -I tools/art/cut_props.py <sheet> <dir> --figure=none --flat=9 --base-shade --colors=64 --names=... --size=...`. Baked by `tools/art/bake_rotation.gd --frames=12 --period=90` (wrap ratio 0.99); 3.84 fps (0.08 turn/s) on the memory clock; the pivot is the hub, 204 px over the tower's base. WORLD-37. Approved with the board docs/design/drafts/guardian_regions_dressing_board.md (user, 2026-11-20: "approved"; the sheets shown at game size before placing). Sized against Ivo's 29 art px (tools/art/region_prop_sizes.json, tools/art/interior_prop_sizes.json).
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, glow, blur, text, people
