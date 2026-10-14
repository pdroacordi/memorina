---
id: frozen_lake_border_cairn
command: generate
target: res://assets/sprites/world/props/frozen_lake/border_cairn.png
size: 52x94
frames: 1
view: side
source: codex
---
A stone border cairn on the ridge between the Frozen Lake and the Wind Orchards, seen straight from the side: a tall narrow stack of flat cold grey-blue stones, the widest slabs at the bottom, one upright pointed stone on top with its tip on the horizontal centre, solid from the bottom to the tip along the centre line, a few small patches of old frost. It stands on the two wall tops at x -3200 (lake_chasm local (0, 6), under `Props`), its centre columns opaque from 6 px under the tops to 88 px over them, past the highest row the lake's far peaks reach over the tops at the ring-limit frame (53 px), so the cut between the two regions' far layers stays behind it; over it only the shared sky shows, which has no vertical scroll (WORLD-33; `backdrop_seams_test.test_a_region_tops_cut_shows_only_the_shared_sky`). The orchestrator's call on "Go ahead with WORLD-31, 32 and 33" (user, 2026-10-13): the answer the user chose for the village gatehouses ("Cover with a tall gate tower (Recommended)") applied to this border. Art only: a prop never collides.
Drawn by Codex (one call, 2026-10-13; our frozen_lake stone tiles, lake_cliff_rock wall and gate_tower prop the only references), kept as tools/art/sources/frozen_lake/border_cairn_codex.png and cut by `python -I tools/art/cut_single_prop.py tools/art/sources/frozen_lake/border_cairn_codex.png assets/sprites/world/props/frozen_lake/border_cairn.png --width=26 --palette=assets/sprites/world/tilesets/frozen_lake/stone.png,assets/sprites/world/props/frozen_lake/fisher_hut_facade.png`: 26 art px wide, 2x density. Anchor (the bottom centre, the scene's -offset): 26,94.
Negative: outlines, black contour, perspective, side faces, snow drifts, glow, text, letters, runes, people, animals, plants, ground, sky, clouds, scenery
