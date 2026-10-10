---
id: playtests/2026-10-10-villagers-and-animals
type: playtest
title: Villagers and animals - twelve idle loops in the village streets, the bakery and the tavern; interiors built of wood, no grass indoors
status: active
tags: [world-10, props, inhabitants, interiors, grass, playtest]
related: [systems/props, systems/grass]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/environment/inhabitants/
---

## Summary

WORLD-10 in the real game (windowed, `tools/playtest`), spring, the village's memory 0.8, two shots 0.6 s apart per spot.

- **People and animals** (`00_board.png`, taken before the elder moved indoors and the baker became the design's woman baker): the cat on Ivo's doorstep, two children by the bench, the water carrier at the well, the seller past the bakery, two hens by the empty house, the farmer on the east road, the taverner behind the bar (head and shoulders over the one-cell counter) and a seated patron. Every spot changed 3,900 to 6,400 px between the shots: the loops run at 0.8 memory.
- **Draw order**: inhabitants stand in front of the house fronts and behind Ivo; no one collides.
- **Interiors** (`01_interiors_wood.png`, `02_bakery_elder_cellar.png`): the tavern, Ivo's house, the bakery and the elder's house are wood planks over the timber wall; the baker woman stands in the bakery and the elder in his house (design 04 section 3.1). The cellar keeps its earth banks for Enraizar and grows no blades: no interior grows grass (`Room.interior`); only the earth's turf lip shows.

## What screenshots cannot show

- The ping-pong loops (0..7..1 at 6 fps) were checked as strips, not as recorded motion.
- The grey (memory below 0.2) was not visited here; `AmbientMotion` holds a frame there, as for every prop (`ambient_motion_test`).
- The four who leave at 0.6 (`RegionPresence` 0.7) were not seen leaving: the drop to 0.6 is MEM-13's, from the second restored guardian.
