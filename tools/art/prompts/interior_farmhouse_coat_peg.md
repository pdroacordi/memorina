---
id: interior_farmhouse_coat_peg
command: generate
target: res://assets/sprites/world/props/interiors/farmhouse/coat_peg.png
size: 50x48
frames: 1
view: side
no_background: true
source: codex
---
Coat peg, a set-dressing prop for the abandoned farmhouse, threshold_farmhouse (WORLD-12), seen straight on from the side, minimalist 16-bit, no outlines, flat colours. Measured height 24 art px against Ivo's 29 (`farmhouse` `coat_peg:h24` in tools/art/interior_prop_sizes.json). Cut from one Codex sheet (tools/art/sources/interiors/farmhouse_props2_codex.png; tools/art/sources/interiors/farmhouse_props_codex.png, our own approved concept, the only reference) by `python -I tools/art/cut_props.py tools/art/sources/interiors/farmhouse_props2_codex.png <dir> --figure=none --flat=9 --base-shade --colors=64 --names=pot,onions_herbs,coat_peg,churn --size=pot:h11,onions_herbs:h17,coat_peg:h26,churn:h17`. Approved with the board docs/design/drafts/early_regions_dressing_board.md (user, 2026-11-22: "approved"; concepts "Approve, fix in sheets (Recommended)"); the sheet is shown to the user before it is placed.
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, glow, blur, text, people
