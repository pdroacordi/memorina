---
id: threshold_thistles
command: generate
target: res://assets/sprites/world/props/threshold/thistles.png
size: 18x24
frames: 1
bands: 3
view: side
no_background: true
source: codex
---
Thistles, a set-dressing prop for Threshold Road (WORLD-12), seen straight on from the side, minimalist 16-bit, no outlines, flat colours. Measured height 12 art px against Ivo's 29 (`threshold` `thistles:h12` in tools/art/region_prop_sizes.json). Cut from one Codex sheet (tools/art/sources/threshold/threshold_nature_codex.png; tools/art/sources/regions/dressing_threshold_concept_codex.png, our own approved concept, the only reference) by `python -I tools/art/cut_props.py tools/art/sources/threshold/threshold_nature_codex.png <dir> --figure=none --flat=9 --base-shade --colors=64 --names=field_tree,scarecrow,-,-,thistles --size=field_tree:h80,scarecrow:h42,thistles:h14`, then `python -I tools/art/season_bands.py <cut> <target> --winter --dry` (drawn in winter, the region's season; spring and autumn recoloured; three bands, "get three", user, 2026-11-22). Approved with the board docs/design/drafts/early_regions_dressing_board.md (user, 2026-11-22: "approved"; concepts "Approve, fix in sheets (Recommended)"); the sheet is shown to the user before it is placed.
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, glow, blur, text, people
