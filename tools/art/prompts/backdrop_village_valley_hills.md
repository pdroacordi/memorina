---
id: backdrop_village_valley_hills
command: generate
target: res://assets/sprites/world/background/village_valley/hills.png
size: 1024x1152
frames: 1
source: codex
---
One layer of `resources/world/backdrops/village_valley.tres`, the village streets' backdrop (design 04 section 6: sky, northern mountains, hills with fields), after the approved concept (tools/art/references/village_concept.png). 1024x384 per band at 2x, spring, autumn and winter stacked; autumn and winter are recolours of the spring drawing; every band mixed toward its season's horizon sky by the layer's depth (`AERIAL` in the tool), so the play plane stands out. Seamless sideways; EDGE rows one colour per band (architecture/vertical-backdrops, "Art contract"). Rolling green hills with patchwork fields and small groves. Cut by `python -I tools/art/cut_backdrop.py layer tools/art/sources/village_valley_hills_codex.png assets/sprites/world/background/village_valley/hills.png --kind=hills --colors=9 --top=94 --cut=28,1384 --overlap=16` (the strip's sea cliff and lighthouse cannot wrap and are left out).
Negative: outlines, sky, clouds, sun, birds, text, frame, speckle, busy texture
