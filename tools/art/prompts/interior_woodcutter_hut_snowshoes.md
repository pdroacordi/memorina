---
id: interior_woodcutter_hut_snowshoes
command: generate
target: res://assets/sprites/world/props/interiors/woodcutter_hut/snowshoes.png
size: 26x36
frames: 1
view: side
no_background: true
source: codex
---
Snowshoes, a set-dressing prop for the woodcutter's hut, woods_hut (WORLD-14), seen straight on from the side, minimalist 16-bit, no outlines, flat colours. Measured height 18 art px against Ivo's 29 (`woodcutter_hut` `snowshoes:h18` in tools/art/interior_prop_sizes.json). Cut from one Codex sheet (tools/art/sources/interiors/woodcutter_hut_sheet_codex.png; tools/art/sources/interiors/fisher_hut_sheet_codex.png, our own approved concept, the only reference) by `python -I tools/art/cut_props.py tools/art/sources/interiors/woodcutter_hut_sheet_codex.png <dir> --figure=none --flat=9 --base-shade --colors=64 --names=hearth_kettle,bed_furs,table,axe_rack,snowshoes,fur_coat,jar_shelf --size=hearth_kettle:w32,bed_furs:w36,table:h16,axe_rack:w28,snowshoes:h20,fur_coat:h22,jar_shelf:w28`. Approved with the board docs/design/drafts/early_regions_dressing_board.md (user, 2026-11-22: "approved"; concepts "Approve, fix in sheets (Recommended)"); the sheet is shown to the user before it is placed.
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, glow, blur, text, people
