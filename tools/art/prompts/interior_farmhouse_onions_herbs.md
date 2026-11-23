---
id: interior_farmhouse_onions_herbs
command: generate
target: res://assets/sprites/world/props/interiors/farmhouse/onions_herbs.png
size: 20x32
frames: 1
view: side
no_background: true
source: codex
---
Onions herbs, a set-dressing prop for the abandoned farmhouse, threshold_farmhouse (WORLD-12), seen straight on from the side, minimalist 16-bit, no outlines, flat colours. Measured height 16 art px against Ivo's 29 (`farmhouse` `onions_herbs:h16` in tools/art/interior_prop_sizes.json). Cut from one Codex sheet (tools/art/sources/interiors/farmhouse_props2_codex.png; tools/art/sources/interiors/farmhouse_props_codex.png, our own approved concept, the only reference) by `python -I tools/art/cut_props.py tools/art/sources/interiors/farmhouse_props2_codex.png <dir> --figure=none --flat=9 --base-shade --colors=64 --names=pot,onions_herbs,coat_peg,churn --size=pot:h11,onions_herbs:h17,coat_peg:h26,churn:h17`. Approved with the board docs/design/drafts/early_regions_dressing_board.md (user, 2026-11-22: "approved"; concepts "Approve, fix in sheets (Recommended)"); the sheet is shown to the user before it is placed. Contrast raised after the WORLD-12..14 playtest (hard to read on plaster at 1x), "Fix them now" (user, 2026-11-23): every colour's value pushed 1.55 times away from the prop's mean; shape and size unchanged.
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, glow, blur, text, people
