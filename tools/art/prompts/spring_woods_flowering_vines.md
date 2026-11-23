---
id: spring_woods_flowering_vines
command: generate
target: res://assets/sprites/world/props/spring_woods/flowering_vines.png
size: 40x72
frames: 1
bands: 3
view: side
no_background: true
source: codex
---
Flowering vines, a set-dressing prop for the Spring Woods (WORLD-14), seen straight on from the side, minimalist 16-bit, no outlines, flat colours. Measured height 36 art px against Ivo's 29 (`spring_woods` `flowering_vines:h36` in tools/art/region_prop_sizes.json). Cut from one Codex sheet (tools/art/sources/spring_woods/woods_big_codex.png; tools/art/sources/regions/dressing_spring_woods_concept_codex.png, our own approved concept, the only reference) by `python -I tools/art/cut_props.py tools/art/sources/spring_woods/woods_big_codex.png <dir> --figure=none --flat=9 --base-shade --colors=64 --names=trunk_base,trunk_section,blossom_tree,fallen_log,hanging_moss,flowering_vines,leaf_cluster --size=trunk_base:w208,trunk_section:w46,blossom_tree:h84,fallen_log:w50,hanging_moss:h33,flowering_vines:h40,leaf_cluster:w39`, then `python -I tools/art/season_bands.py <cut> <target>` (drawn in spring, the woods' season; autumn and winter recoloured; three bands, "get three", user, 2026-11-22). Soft pink flowers (concept fix, user, 2026-11-22). Approved with the board docs/design/drafts/early_regions_dressing_board.md (user, 2026-11-22: "approved"; concepts "Approve, fix in sheets (Recommended)"); the sheet is shown to the user before it is placed. Reworked after the WORLD-12..14 playtest (leaves lost against the green backdrop, three flowers showing), "Fix them now" (user, 2026-11-23): band 0's leaves mapped by brightness onto darker greens (34,58,38) to (84,118,60), a 2x2 art px blossom added every 5 art rows down its length on alternate sides, then rebanded with `season_bands.py`; size unchanged.
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, glow, blur, text, people
