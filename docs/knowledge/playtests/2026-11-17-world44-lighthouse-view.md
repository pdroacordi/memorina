---
id: playtests/2026-11-17-world44-lighthouse-view
type: playtest
title: WORLD-44 - the lighthouse base opens east over the lookout
status: active
build: uncommitted WORLD-44 change over f548cc9d
area_tested: "lighthouse_base from (12080, -940), Memorina and sword owned; then a run east into the edge."
tags: [world-44, rooms, frost-edge, lighthouse, playtest]
related: [systems/rooms, systems/backdrops]
created: 2026-11-17
updated: 2026-11-17
ratings: { fun: 0, fluidity: 0, aesthetics: 0 }
screenshots:
  - screenshots/2026-11-17-world44-lighthouse-view/before.png
  - screenshots/2026-11-17-world44-lighthouse-view/after.png
---

# WORLD-44: the lighthouse base's east end

- Before, a brick column stood at the room's east edge over the lookout (`before`). After, the backdrop's sky and clouds run to the frame's edge (`after`).
- Holding right, Ivo stops at x 12149 with `vel` 0, on the floor: `WorldEdges` holds him at the room's edge (x 12160).
- The camera stops at the room's edge, so nothing past x 12160 is in view; the sea below the lookout is not in this room's frame.
