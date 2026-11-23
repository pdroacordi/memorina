---
id: frost_edge_hammock
command: generate
target: res://assets/sprites/world/props/frost_edge/hammock.png
size: 80x32
frames: 1
view: side
no_background: true
source: codex
---
Hammock, a set-dressing prop for the Frost Edge and the lighthouse (WORLD-13), seen straight on from the side, minimalist 16-bit, no outlines, flat colours. Measured width 40 art px against Ivo's 29 (`frost_edge` `hammock:w40` in tools/art/region_prop_sizes.json). Cut from one Codex sheet (tools/art/sources/frost_edge/frost_hold_keeper_codex.png; tools/art/sources/regions/dressing_frost_edge_concept_codex.png, our own approved concept, the only reference) by `python -I tools/art/cut_props.py tools/art/sources/frost_edge/frost_hold_keeper_codex.png <dir> --figure=none --flat=9 --base-shade --colors=64 --names=hammock,ship_lantern,cargo_net,sea_chest,cot,logbook_stand,keeper_chair --size=hammock:w42,ship_lantern:h16,cargo_net:w42,sea_chest:h13,cot:w34,logbook_stand:h20,keeper_chair:h19`. Approved with the board docs/design/drafts/early_regions_dressing_board.md (user, 2026-11-22: "approved"; concepts "Approve, fix in sheets (Recommended)"); the sheet is shown to the user before it is placed.
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, glow, blur, text, people
