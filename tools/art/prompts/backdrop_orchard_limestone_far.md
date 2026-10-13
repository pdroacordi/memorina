---
id: backdrop_orchard_limestone_far
command: generate
target: res://assets/sprites/world/background/orchard_limestone/far.png
size: 512x512
frames: 1
source: codex
---
The backdrop wall of `resources/world/backdrops/orchard_limestone.tres`, for the cliff chimney and the counterweights shaft: limestone cliff in rough horizontal beds split by dark cracks. "Our own per region (Recommended)" (user, 2026-10-13): rooms inside rock get a rock wall; "One rock, two palettes (Recommended)": the sea-cliff and lake walls are the same family as the region's rock. Opaque, repeats on both axes, one band (no seasons inside rock), drawn at 2x, one value step darker than the ground in front of it (architecture/backdrop-seams, "Art contracts"). Codex drew a square seamless texture for the approved board (our `ice_caves` and `earth_caves` walls as the style references), kept in `tools/art/sources/backdrop_orchard_limestone_codex.png`; cut by `python -I tools/art/cut_wall.py tools/art/sources/backdrop_orchard_limestone_codex.png assets/sprites/world/background/orchard_limestone/far.png --colors=#2e2922,#3a342b,#474035`: reduced to 256 art px, 5 colours, each wrap stitched along the cut of least difference, values mapped onto these colours. Reference: the approved board `tools/art/references/regions/board_wind_orchards.png`. Approved board (2026-10-13): "Approve, fix the flat ground (Recommended)" - "Approve all six. In production: the Threshold and Orchard ground came out nearly flat beige, so give them texture (stones, roots, slabs) like our village earth; brighten the Frost Edge sea; make the woods trees less dense and the orchard windmills bigger."
Negative: outlines, perspective, light source, glow, vignette, border, objects, creatures, text, speckle, high contrast
