---
id: spring_woods_blossom_heap
command: generate
target: res://assets/sprites/world/props/spring_woods/blossom_heap.png
size: 160x40
frames: 1
bands: 3
view: side
no_background: true
source: codex
---
Blossom heap, a set-dressing prop for the Spring Woods (WORLD-14), seen straight on from the side, minimalist 16-bit, no outlines, flat colours. Measured width 44 art px against Ivo's 29 (`spring_woods` `blossom_heap:w44` in tools/art/region_prop_sizes.json). Cut from one Codex sheet (tools/art/sources/spring_woods/woods_small_codex.png; tools/art/sources/regions/dressing_spring_woods_concept_codex.png, our own approved concept, the only reference) by `python -I tools/art/cut_props.py tools/art/sources/spring_woods/woods_small_codex.png <dir> --figure=none --flat=9 --base-shade --colors=64 --names=log_stack,saw_horse,hand_cart,birdhouse_post,mossy_stump,mossy_rock,flowering_bush,ferns,mushrooms,shelf_fungus,wood_knot,resin_streak,cracked_mud,dead_reeds,lily_pad,blossom_heap --size=log_stack:h18,saw_horse:h16,hand_cart:w40,birdhouse_post:h40,mossy_stump:h18,mossy_rock:h14,flowering_bush:h17,ferns:h16,mushrooms:h10,shelf_fungus:w16,wood_knot:h16,resin_streak:h24,cracked_mud:w52,dead_reeds:h19,lily_pad:w16,blossom_heap:w48`, then `python -I tools/art/season_bands.py <cut> <target>` (drawn in spring, the woods' season; autumn and winter recoloured; three bands, "get three", user, 2026-11-22). WORLD-41's heap where the terraces drop lands in woods_canopy; soft pink (concept fix, user, 2026-11-22). Approved with the board docs/design/drafts/early_regions_dressing_board.md (user, 2026-11-22: "approved"; concepts "Approve, fix in sheets (Recommended)"); the sheet is shown to the user before it is placed. Redrawn larger after the WORLD-12..14 playtest (75 px wide against a 160 px soft zone, half hidden by grass), "Fix them now" (user, 2026-11-23): PixelLab `generate` (pixflux, 160x48, flat shading) of a low wide heap of fallen blossom and moss, shrunk by block majority to 80x20 art px with a darker bottom row, then `season_bands.py` (spring input); source `tools/art/sources/spring_woods/blossom_heap_pixellab.png`. Measured: w80 art px (the zone's 160 px), 20 tall.
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, glow, blur, text, people
