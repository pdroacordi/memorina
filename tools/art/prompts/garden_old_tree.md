---
id: garden_old_tree
command: generate
target: res://assets/sprites/world/props/garden/old_tree.png
size: 304x272
frames: 1
bands: 3
view: side
direction: west
no_background: true
source: codex
---
The old broad tree of the waterfall garden (STORY-05, design drafts/camada_pessoal.md section 1): a thick gnarled trunk with root flares, a broad rounded crown over the trunk and to the left, and one thick LOW bare branch reaching right to a small leafy tip, from which the swing hangs. Spring art; three season bands (`prop_seasonal_material.tres`). Measured (game px, origin the sprite's bottom centre, offset -152,-272): the trunk's centre is at x -68; the branch's underside is 92 px over the floor at x +50 to +66, 88 at x +74 to +90, and the branch reaches x +146. Placing the tree's origin 62 px left of the swing's centre puts the swing's ropes under the branch at 92 and 88. Drawn at 152x136 art px and scaled 2x. Drawn by Codex (two calls, 2026-11-12; the first put the branch at a fifth of the height, `old_tree_codex_first.png`; the village tree the only style reference), kept as tools/art/sources/props/garden/old_tree_codex.png and cut by `python -I tools/art/cut_single_prop.py tools/art/sources/props/garden/old_tree_codex.png <cut> --width=0 --height=136 --parts --palette=tools/art/sources/props/garden/garden_tree_palette.png --flat=9` (the village tree's greens and browns plus two bark tones; flattened in its own colours the bark highlight turned khaki), then `python -I tools/art/season_bands.py <cut> assets/sprites/world/props/garden/old_tree.png`.
The garden concept `tools/art/references/regions/garden_concept.png` is approved for look and mood only: "Isso é apenas o conceito, certo? Se sim, aprovada. Na implementação real, a água tem que ser das nossas, gerada automaticamente, com reflexo. E deve ser mais perto dos personagens para que fique um cenário bem bonito" (user, 2026-11-12). Not yet seen by the user in the room.
Negative: outlines, black contour, swing, rope, ground, grass, scenery, text
