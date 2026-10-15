---
id: gotchas/a-room-stacked-over-a-gap-clips-the-running-jump
type: gotcha
title: A room stacked over a jumpable gap clips the running jump - its bottom cells stop Ivo by their side face
status: active
tags: [rooms, room-map, world-layout, jump, world-35]
related: [systems/rooms, systems/world, gotchas/a-one-screen-shaft-cannot-shut-out-wall-climb]
created: 2026-10-14
updated: 2026-10-15
source_files:
  - scenes/world/rooms/frozen_lake/contents/lake_icefall.room
  - scenes/world/rooms/threshold/contents/threshold_bridge.room
---

# A room stacked over a gap clips the running jump

**Rule:** when a new room sits over an open-topped room, no solid cell of its bottom two rows (64 px) may lie over
a running jump's arc. Over a jumped gap, leave those cells air or one-way (`=`). A room edge column there can be
air only where the room below has a sky band beside it, or the audit reports `OPEN_EDGE`.

- **Why.** The base running jump from a floor 5 rows under the room's top peaks at feet y 16, head -38. A solid
  cell above that arc is first met by its side face, and the jump stops dead (`vx = 0`) and drops. It is not
  bonked from below.
- **Measured (WORLD-35 step 3, a scratch Python sim, then `world35s3_g_gap_jump`).** The first drafts put lake_icefall's bottom
  over threshold_bridge cols 20-39; today threshold_icefall_foot lies there. The gap (cols 17-22) is one running jump
  from the west deck.
  - In the first draft, a single solid cell over bridge col 20 stopped the jump at x 7029.
  - A solid floor from bridge col 23 stopped it at x 7125, into the ravine.
  - From col 26 on, every take-off between x 6930 and 6967 lands on the east deck.
  - The built room over the bridge, threshold_icefall_foot, keeps rows 9-11 open over cols 20-38: col 0 there is
    air only in rows 10-11, over the bridge's sky band, and the rock starts at y -96. The windowed run lands on the
    deck at x 7148.
- **The same cells cap the deck's own jump.** A room over a walkable floor caps every jump there at its underside.
  Keep that underside above a base jump's head (y -38 from a floor at row 5). Then a double jump stops on it before
  its feet rise the 64 px that swaps rooms (`RoomExit`): rock at y -96 holds the feet at y -42.
- A double jump's head reaches 152 px over the top (the band's ceiling caps it), so a double jump across such a
  gap may still meet higher cells. The single jump is the gate.
