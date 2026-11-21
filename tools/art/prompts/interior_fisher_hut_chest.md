---
id: interior_fisher_hut_chest
command: generate
target: res://assets/sprites/world/props/interiors/fisher_hut/chest.png
size: 30x20
frames: 1
view: side
no_background: true
source: codex
---
Chest, a set-dressing prop for the fisherman's hut, lake_fisher_hut (WORLD-15), seen straight on from the side, minimalist 16-bit, no outlines, flat colours. Cut from one Codex sheet (tools/art/sources/interiors/fisher_hut_sheet_codex.png; tools/art/references/village_concept.png the only reference) by `python -I tools/art/cut_props.py <sheet> <dir> --figure=none --flat=9 --base-shade --colors=64 --names=... --size=...`. Approved with the board docs/design/drafts/guardian_regions_dressing_board.md (user, 2026-11-20: "approved"; the sheets shown at game size before placing). Sized against Ivo's 29 art px (tools/art/region_prop_sizes.json, tools/art/interior_prop_sizes.json).
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, glow, blur, text, people
