---
id: threshold_wheat_short
command: generate
target: res://assets/sprites/world/props/threshold/wheat_short.png
size: 50x36
frames: 4
bands: 3
view: side
no_background: true
source: codex
---
Wheat short, a set-dressing prop for Threshold Road (WORLD-12), seen straight on from the side, minimalist 16-bit, no outlines, flat colours. Measured height 18 art px against Ivo's 29 (`threshold` `wheat_short:h18` in tools/art/region_prop_sizes.json). Cut from one Codex sheet (tools/art/sources/threshold/threshold_wheat_codex.png; tools/art/sources/regions/dressing_threshold_concept_codex.png, our own approved concept, the only reference) by `python -I tools/art/cut_props.py tools/art/sources/threshold/threshold_wheat_codex.png <dir> --figure=none --flat=9 --base-shade --colors=64 --names=wheat_tall,wheat_short --size=wheat_tall:h23,wheat_short:h18`, then `python -I tools/art/season_bands.py <cut> <target> --winter --dry` (drawn in winter, the region's season; spring and autumn recoloured; three bands, "get three", user, 2026-11-22). Held in the same gust as wheat_tall (concept fix, user, 2026-11-22). Sways in a 4-frame loop through AmbientMotion ("Sway loops, keep the hold (Recommended)" (user, 2026-11-23)), each band through `draw_ambient_frames.py sway` as wheat_tall; held frozen mid-sway by `FieldsStillMemory` ("Hold the fields still (Recommended)", user, 2026-11-22) until a pulse. Approved with the board docs/design/drafts/early_regions_dressing_board.md (user, 2026-11-22: "approved"; concepts "Approve, fix in sheets (Recommended)"); the sheet is shown to the user before it is placed.
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, glow, blur, text, people
