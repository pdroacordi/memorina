---
id: frost_edge_flagpole
command: generate
target: res://assets/sprites/world/props/frost_edge/flagpole.png
size: 72x140
frames: 6
view: side
no_background: true
source: codex
---
Flagpole, a set-dressing prop for the Frost Edge and the lighthouse (WORLD-13), seen straight on from the side, minimalist 16-bit, no outlines, flat colours. Measured height 70 art px against Ivo's 29 (`frost_edge` `flagpole:h70` in tools/art/region_prop_sizes.json). Cut from one Codex sheet (tools/art/sources/frost_edge/frost_shore_built_codex.png; tools/art/sources/regions/dressing_frost_edge_concept_codex.png, our own approved concept, the only reference) by `python -I tools/art/cut_props.py tools/art/sources/frost_edge/frost_shore_built_codex.png <dir> --figure=none --flat=9 --base-shade --colors=64 --names=figurehead,mast_snapped,anchor,buoy,bollard,fog_bell,flagpole,railing,oil_cans,coal_bin,storm_lantern,blanket_folded --size=figurehead:w51,mast_snapped:h68,anchor:h28,buoy:h14,bollard:h14,fog_bell:h38,flagpole:h75,railing:h16,oil_cans:h14,coal_bin:h14,storm_lantern:h14,blanket_folded:w18`. The pennant flies in a 6-frame loop through AmbientMotion ("Sway loops, keep the hold (Recommended)" (user, 2026-11-23)): `python -I tools/art/draw_ambient_frames.py wave <still> <strip> --hinge=9 --box=10:0:36:24 --frames=6` (art columns right of the pole shift 0, 1, 1, 0, -1, -1 art px at the tip); frame 0 is the still. At memory 0.05 it stands frozen mid-flap and moves only inside a pulse. The cut's red specks on the pole (art columns 0-9, rows 5 down) were repainted with the pole's grey (96, 100, 99); the pennant keeps its red ("Fix the weak ones, then place (Recommended)", user, 2026-11-23). Approved with the board docs/design/drafts/early_regions_dressing_board.md (user, 2026-11-22: "approved"; concepts "Approve, fix in sheets (Recommended)"); the sheet is shown to the user before it is placed.
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, glow, blur, text, people
