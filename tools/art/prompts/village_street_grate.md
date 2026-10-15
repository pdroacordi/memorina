---
id: village_street_grate
command: generate
target: res://assets/sprites/world/props/fact_barrier/street_grate.png
size: 128x32
frames: 1
view: side
source: procedural: tools/art/draw_street_grate.py
---
A heavy iron grate set flush into the village's dirt road, seen from the side, between two cut-stone blocks. It is the art of the `FactGrate` (`fact_grate.tscn`, the `FactBarrier` script with a floor shape) over the hatch in village_gate_east's road (cols 29-32), where caldera_sun_stair ends in a stone vault. It stays solid road until the summer guardian is restored (`guardian_restored_summer.tres`); then it is gone and leaves the hole (WORLD-35 step 5). User, 2026-10-14: "Grate in the village road (Recommended)": "The stair ends under a grate in village_gate_east's street: a hatch in the flat street, so the village stays one street (your 'village is not for exploring' rule)."; "When the guardian is restored (Recommended)": "The grate opens once the summer guardian is restored; it reuses the existing fence logic, no new code.".
Measured: 128x32, the whole four-cell floor row, top edge on the road's surface line, centred at scene position 48,-16 from its west cell's floor point. Drawn at 64x16 art px and scaled 2x.
- Each end: a stone block 6 art px wide with one course line, in the village cobble colours sampled from `assets/sprites/world/tilesets/village/stone.png`.
- Between the blocks: an iron frame, bars 2 art px wide every 4 art px, and one cross bar, in the fact barrier's iron colours.
- The gaps between the bars stay transparent, so the vault shows through from the street.
Drawn by `python -I tools/art/draw_street_grate.py assets/sprites/world/props/fact_barrier/street_grate.png`, with no reference. Orchestrator call, 2026-10-15: the script reads crisper at 64x16 art px than Codex cuts did; precedent `draw_post.py`.
Negative: outlines, black contour, perspective, cobbles beyond the frame, grass, manhole lid, text
