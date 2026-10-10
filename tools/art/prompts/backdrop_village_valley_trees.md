---
id: backdrop_village_valley_trees
command: generate
target: res://assets/sprites/world/background/village_valley/trees.png
size: 1024x1152
frames: 1
source: codex
---
One layer of `resources/world/backdrops/village_valley.tres`, the village streets' backdrop (design 04 section 6: sky, northern mountains, hills with fields), after the approved concept (tools/art/references/village_concept.png). 1024x384 per band at 2x, spring, autumn and winter stacked; autumn and winter are recolours of the spring drawing; every band mixed toward its season's horizon sky by the layer's depth (`AERIAL` in the tool), so the play plane stands out. Seamless sideways; EDGE rows one colour per band (architecture/vertical-backdrops, "Art contract"). The near tree line: rounded crowns and a few pines in two or three greens. Cut by `python -I tools/art/cut_backdrop.py layer tools/art/sources/village_valley_trees_codex.png assets/sprites/world/background/village_valley/trees.png --kind=trees --cut=108,1499 --colors=6 --top=106`.
Negative: outlines, sky, clouds, sun, birds, text, frame, speckle, busy texture
