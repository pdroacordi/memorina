---
id: orchard_dry_grass
command: generate
target: res://assets/sprites/world/props/wind_orchards/dry_grass.png
size: 34x16
frames: 1
bands: 3
view: side
no_background: true
source: codex
---
Dry grass, a set-dressing prop for the Wind Orchards (WORLD-16), seen straight on from the side, minimalist 16-bit, no outlines, flat colours. Cut from one Codex sheet (tools/art/sources/wind_orchards/orchard_built_codex.png, tools/art/sources/wind_orchards/orchard_nature_codex.png, tools/art/sources/wind_orchards/great_windmill_codex.png; tools/art/references/village_concept.png the only reference) by `python -I tools/art/cut_props.py <sheet> <dir> --figure=none --flat=9 --base-shade --colors=64 --names=... --size=...`, then `python -I tools/art/season_bands.py <cut> <target> --autumn` (drawn in autumn; three bands). Approved with the board docs/design/drafts/guardian_regions_dressing_board.md (user, 2026-11-20: "approved"; the sheets shown at game size before placing). Sized against Ivo's 29 art px (tools/art/region_prop_sizes.json, tools/art/interior_prop_sizes.json).
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, glow, blur, text, people
