---
id: gotchas/zigzag-ledges-two-rows-apart-seal-a-shaft
type: gotcha
title: Zigzag ledges two rows apart seal a shaft - Ivo (54 px) does not fit the 32 px corner gap
status: active
tags: [rooms, room-map, authoring, ledges, shaft, world-05]
related: [bugs/the-village-cistern-shaft-is-sealed-by-its-new-ledges, bugs/a-redoma-first-player-is-trapped-in-the-summer-caldera, systems/rooms, systems/world]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/rooms/home_village/contents/village_cistern.room
---

# Zigzag ledges two rows apart seal a shaft

**Rule:** in a `.room` shaft climbed by ledges on alternating sides, put consecutive ledges at least
3 rows apart (a 96 px rise). Two rows apart leaves 32 px between one ledge's underside and the next
ledge's top where they meet corner to corner; Ivo is 54 px tall and cannot pass, up or down.

**Measured (2026-10-10, orchards and caldera re-verification):** the cistern's ledges at rows 13, 15,
18 and 22 sealed the shaft both ways. Moving the row-15 ledge to row 16 only moved the 32 px gap down
one pair (rows 16/18). Re-laid at rows 22, 19, 16 and 13, every corner has 64 px.

- A stone ledge directly over a drop hole also caps a jump up through it. Make it a one-way `=`
  (the row-19 ledge over the cistern's drop hole).
- The check: for each pair of ledges that touch at a corner, at least 2 rows (64 px) between the upper
  ledge's underside and the lower ledge's top. The playtester measures it with a closed-loop climb in
  each direction.
