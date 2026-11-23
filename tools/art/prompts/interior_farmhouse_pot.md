---
id: interior_farmhouse_pot
command: generate
target: res://assets/sprites/world/props/interiors/farmhouse/pot.png
size: 32x26
frames: 1
view: side
no_background: true
source: codex
---
Pot, a set-dressing prop for the abandoned farmhouse, threshold_farmhouse (WORLD-12), seen straight on from the side, minimalist 16-bit, no outlines, flat colours. Measured height 13 art px against Ivo's 29 (`farmhouse` `pot:h13` in tools/art/interior_prop_sizes.json). Cut from one Codex sheet (tools/art/sources/interiors/farmhouse_props2_codex.png; tools/art/sources/interiors/farmhouse_props_codex.png, our own approved concept, the only reference) by `python -I tools/art/cut_props.py tools/art/sources/interiors/farmhouse_props2_codex.png <dir> --figure=none --flat=9 --base-shade --colors=64 --names=pot,onions_herbs,coat_peg,churn --size=pot:h11,onions_herbs:h17,coat_peg:h26,churn:h17`. The Codex cut (tools/art/sources/interiors/farmhouse_props2_codex.png, cut as for its sheet) turned to mush, so it was redrawn at its art size by PixelLab pixflux with that cut, bottom-centred on a 32x32 canvas, as the init image (`tools/pixellab/pixellab.ps1 generate -Width 32 -Height 32 -NoBackground -Shading "flat shading" -Detail "low detail" -Outline lineless -InitStrength 60 -Reference tools/art/sources/interiors/pixellab/farmhouse_pot_init.png`, described as "a black iron cooking pot with a lid knob, two side handles and three short legs"; raw kept as tools/art/sources/interiors/pixellab/farmhouse_pot_px.png) and cleaned by `python -I tools/art/clean_prop.py tools/art/sources/interiors/pixellab/farmhouse_pot_px.png <target> --flat=10 --base-shade --drop-specks=4`; no palette snap, the sheet has no iron greys. Redrawn because the cut was unreadable at game size ("Fix the weak ones, then place (Recommended)", user, 2026-11-23). Approved with the board docs/design/drafts/early_regions_dressing_board.md (user, 2026-11-22: "approved"; concepts "Approve, fix in sheets (Recommended)"); the sheet is shown to the user before it is placed.
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, glow, blur, text, people
