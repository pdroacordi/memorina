---
id: frozen_lake_fish_rack
command: generate
target: res://assets/sprites/world/props/frozen_lake/fish_rack.png
size: 74x56
frames: 4
view: side
no_background: true
source: codex
---
Fish rack, a set-dressing prop for the Frozen Lake (WORLD-15), seen straight on from the side, minimalist 16-bit, no outlines, flat colours. Cut from one Codex sheet (tools/art/sources/frozen_lake/lake_built_codex.png, tools/art/sources/frozen_lake/lake_ice_codex.png; tools/art/references/village_concept.png the only reference) by `python -I tools/art/cut_props.py <sheet> <dir> --figure=none --flat=9 --base-shade --colors=64 --names=... --size=...`. Sways on the memory clock: `python -I tools/art/sway_between_posts.py <still> <strip> --posts=4,32 --hinge=6` (4 frames, 3 fps, `AmbientMotion`). Approved with the board docs/design/drafts/guardian_regions_dressing_board.md (user, 2026-11-20: "approved"; the sheets shown at game size before placing). Sized against Ivo's 29 art px (tools/art/region_prop_sizes.json, tools/art/interior_prop_sizes.json).
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, glow, blur, text, people
