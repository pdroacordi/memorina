---
id: backdrop_spring_woods_far
command: generate
target: res://assets/sprites/world/background/spring_woods/far.png
size: 1024x1152
frames: 1
source: codex
---
The far layer of `resources/world/backdrops/spring_woods.tres` (design 04 section 6: layered trunks and blossoming canopies): a misty forest of enormous pale trunks and high canopies. Backdrops: "Our own per region (Recommended)" (user, 2026-10-13) - one set per region, the shared sky (`village_valley/sky.png`, `backdrop_village_valley_sky`) and the shared horizon: horizon row 229, eye level 191, scroll 0.12, 0.07 as on the board and in `village_valley.tres`. 1024x384 per band at 2x, spring, autumn and winter stacked, autumn and winter recoloured from the spring drawing (kind `trees`); every band mixed toward its season's horizon sky by 0.5 (atmospheric depth); silhouette top at art row 18; 6 colours. Seamless sideways; EDGE rows one colour per band (architecture/vertical-backdrops, "Art contract"). The Codex strip drawn for the approved board. Raw kept in `tools/art/sources/spring_woods_far_codex.png`; cut by `python -I tools/art/cut_backdrop.py layer tools/art/sources/spring_woods_far_codex.png assets/sprites/world/background/spring_woods/far.png --kind=trees --colors=6 --top=18 --aerial=0.5`. Reference: the approved board `tools/art/references/regions/board_spring_woods.png`; our village concept and the village valley's spring band were the Codex style references. Approved board (2026-10-13): "Approve, fix the flat ground (Recommended)" - "Approve all six. In production: the Threshold and Orchard ground came out nearly flat beige, so give them texture (stones, roots, slabs) like our village earth; brighten the Frost Edge sea; make the woods trees less dense and the orchard windmills bigger." Tiles: "Own tiles per region (Recommended)"; "We should only our set of tiles from now on and not mix em."
Negative: outlines, sky, clouds, sun, birds, snow, ice, text, frame, speckle, busy texture
