---
id: frost_edge_gull_nest
command: generate
target: res://assets/sprites/world/props/frost_edge/gull_nest.png
size: 28x16
frames: 1
bands: 3
view: side
no_background: true
source: codex
---
Gull nest, a set-dressing prop for the Frost Edge and the lighthouse (WORLD-13), seen straight on from the side, minimalist 16-bit, no outlines, flat colours. Measured width 14 art px against Ivo's 29 (`frost_edge` `gull_nest:w14` in tools/art/region_prop_sizes.json). Cut from one Codex sheet (tools/art/sources/frost_edge/frost_nature_codex.png; tools/art/sources/regions/dressing_frost_edge_concept_codex.png, our own approved concept, the only reference) by `python -I tools/art/cut_props.py tools/art/sources/frost_edge/frost_nature_codex.png <dir> --figure=none --flat=9 --base-shade --colors=64 --names=kelp_rock,beach_grass,ice_crust,frozen_spray,gull_nest --size=kelp_rock:h14,beach_grass:h11,ice_crust:w38,frozen_spray:h24,gull_nest:w16`, then `python -I tools/art/season_bands.py <cut> <target> --winter --keep-white --twigs` (drawn in winter, the region's season; spring and autumn recoloured; three bands, "get three", user, 2026-11-22). Its white feathers stay white in every band and only the twigs take the season (`--keep-white --twigs`; "Fix the weak ones, then place (Recommended)", user, 2026-11-23). Approved with the board docs/design/drafts/early_regions_dressing_board.md (user, 2026-11-22: "approved"; concepts "Approve, fix in sheets (Recommended)"); the sheet is shown to the user before it is placed.
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, glow, blur, text, people
