---
id: spring_woods_hanging_moss
command: generate
target: res://assets/sprites/world/props/spring_woods/hanging_moss.png
size: 38x62
frames: 4
bands: 3
view: side
no_background: true
source: codex
---
Hanging moss, a set-dressing prop for the Spring Woods (WORLD-14), seen straight on from the side, minimalist 16-bit, no outlines, flat colours. Measured height 31 art px against Ivo's 29 (`spring_woods` `hanging_moss:h31` in tools/art/region_prop_sizes.json). Cut from one Codex sheet (tools/art/sources/spring_woods/woods_big_codex.png; tools/art/sources/regions/dressing_spring_woods_concept_codex.png, our own approved concept, the only reference) by `python -I tools/art/cut_props.py tools/art/sources/spring_woods/woods_big_codex.png <dir> --figure=none --flat=9 --base-shade --colors=64 --names=trunk_base,trunk_section,blossom_tree,fallen_log,hanging_moss,flowering_vines,leaf_cluster --size=trunk_base:w208,trunk_section:w46,blossom_tree:h84,fallen_log:w50,hanging_moss:h33,flowering_vines:h40,leaf_cluster:w39`, then `python -I tools/art/season_bands.py <cut> <target>` (drawn in spring, the woods' season; autumn and winter recoloured; three bands, "get three", user, 2026-11-22). Sways on the memory clock (board: hanging moss, 4 frames): `python -I tools/art/draw_ambient_frames.py swing <still> <strip> --hinge=1` before banding. Approved with the board docs/design/drafts/early_regions_dressing_board.md (user, 2026-11-22: "approved"; concepts "Approve, fix in sheets (Recommended)"); the sheet is shown to the user before it is placed.
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, glow, blur, text, people
