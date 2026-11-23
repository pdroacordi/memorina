---
id: frost_edge_fog_bell
command: generate
target: res://assets/sprites/world/props/frost_edge/fog_bell.png
size: 40x72
frames: 1
view: side
no_background: true
source: codex
---
Fog bell, a set-dressing prop for the Frost Edge and the lighthouse (WORLD-13), seen straight on from the side, minimalist 16-bit, no outlines, flat colours. Measured height 36 art px against Ivo's 29 (`frost_edge` `fog_bell:h36` in tools/art/region_prop_sizes.json). Cut from one Codex sheet (tools/art/sources/frost_edge/frost_shore_built_codex.png; tools/art/sources/regions/dressing_frost_edge_concept_codex.png, our own approved concept, the only reference) by `python -I tools/art/cut_props.py tools/art/sources/frost_edge/frost_shore_built_codex.png <dir> --figure=none --flat=9 --base-shade --colors=64 --names=figurehead,mast_snapped,anchor,buoy,bollard,fog_bell,flagpole,railing,oil_cans,coal_bin,storm_lantern,blanket_folded --size=figurehead:w51,mast_snapped:h68,anchor:h28,buoy:h14,bollard:h14,fog_bell:h38,flagpole:h75,railing:h16,oil_cans:h14,coal_bin:h14,storm_lantern:h14,blanket_folded:w18`. Approved with the board docs/design/drafts/early_regions_dressing_board.md (user, 2026-11-22: "approved"; concepts "Approve, fix in sheets (Recommended)"); the sheet is shown to the user before it is placed.
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, glow, blur, text, people
