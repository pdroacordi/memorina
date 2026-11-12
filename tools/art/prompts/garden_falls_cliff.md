---
id: garden_falls_cliff
command: generate
target: res://assets/sprites/world/props/garden/falls_cliff.png
size: 212x370
frames: 1
view: side
direction: west
no_background: true
source: codex
---
The mossy cliff the big waterfall falls down, replacing `waterfall_ledge`: warm grey-brown stone in blocky facets, moss cushions and hanging moss on its ledges, a mossy crest with two ferns, an irregular stepped left edge (it meets the bank) and a straight right edge (opaque from y 26 down; it tucks behind the room's `S` tiles, which draw over props). A dark wet channel without moss runs top to bottom at x 126-169 (centre 148): the fall (`garden_falls`, 104 px wide) draws over it and hides it. The bottom row is straight and goes into the pool (water at z 50 covers it). 106x185 art px. Drawn by Codex (one call, 2026-11-12; a crop of the board's cliff the reference), kept as tools/art/sources/props/garden/falls_cliff_codex.png and cut by `python -I tools/art/cut_single_prop.py tools/art/sources/props/garden/falls_cliff_codex.png assets/sprites/world/props/garden/falls_cliff.png --width=106 --parts --flat=9 --resnap=tools/art/sources/props/garden/garden_cliff_palette.png --palette= --box=0,0,924,1536` (the box drops a fern tip past the straight edge). `garden_cliff_palette.png` is 9 colours sampled from the board's cliff (k-means), its sky and mist tones dropped and a darker stone added for the channel.
Board: `tools/art/references/regions/garden_concept_v2.png`, "Aprovar a prancha" (user, 2026-11-12). The user's notes with it, as relayed: the place is the foot of the waterfall that is the source of the village river; one pool only, in front of the characters, full width at the bottom of the screen, drawn by the game's own water with reflections, never painted; the waterfall tall, close, at the right, falling straight into that front pool beside the bank; the lantern's light is code; sky and light per flashback: 1 morning, 2 day, 3 late afternoon, 4 moonlit night, 5 darkening twilight, the epilogue late afternoon.
Negative: outlines, black contour, water, waterfall, sky, scenery, text
