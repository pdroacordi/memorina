---
id: hanging_cocoon
command: generate
target: res://assets/sprites/world/props/hanging_cocoon/hanging_cocoon.png
size: 32x48
frames: 1
view: side
direction: west
no_background: true
source: codex
---
A giant ripe pear on its short stalk, golden yellow with a russet-orange blush, one small dry leaf at the stalk. The hanging load (`scenes/world/interactables/hanging_load/hanging_load.tscn`) in every room (the Wind Orchards and the Empty House; also the song trials) (WORLD-42; "Per-region variants", user, 2026-11-11). It is something autumn ripens and lets fall, so Soltar reads as the season letting go: "na minha opiniao nao faz sentido os sprites desenhados pro contexto da habilidade. a habilidade faz isso aí cair por ser outono né. No caso ou a habilidade ou o sprite nao fazem sentido" and "A ripe fruit on its stalk (Recommended)" (user, 2026-11-11; design 02 §5, Soltar: "frutos, casulos"). The Line2D above it is its stalk, hanging from a tree prop's bough placed in each room (orchard_pear_tree, orchard_pear_limb, interior_empty_house_pear_tree_indoor): "as frutas não podem ser simplesmente penduradas no teto. Devem ter contexto. Uma árvore ou algo assim." (user, 2026-11-11). The village's gourd was dropped for the pear once a pear tree grew into the house ("qual o sentido de uma fruta dentro de casa?", "A tree grown into the house (Recommended)", user, 2026-11-11). Measured: 32x48 centred on the body (collision 28x44); drawn at 16x24 art px and scaled 2x.
Drawn by Codex (one call, 2026-11-11; tools/art/references/regions/board_wind_orchards.png the only reference), kept as tools/art/sources/puzzles/load_pear_orchard_codex.png and cut by `python -I tools/art/cut_single_prop.py tools/art/sources/puzzles/load_pear_orchard_codex.png assets/sprites/world/props/hanging_cocoon/hanging_cocoon.png --width=16 --height=24 --parts --palette= `.
Approved: "está ok" (user, 2026-11-11).
Negative: outlines, black contour, face, eyes, worm, branch, tree, scenery, text
