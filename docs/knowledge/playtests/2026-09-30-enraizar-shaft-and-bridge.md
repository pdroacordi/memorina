---
id: playtests/2026-09-30-enraizar-shaft-and-bridge
type: playtest
title: Enraizar's web climbed out of the shaft and its bridge crossed from the ledge
status: active
tags: [enraizar, climbing, root-bridge, shaft, trials]
related: [architecture/roots-join-earth-to-earth]
created: 2026-09-30
updated: 2026-09-30
source_files:
  - tools/playtest/scripts/song_root_shaft_climb.json
  - tools/playtest/scripts/song_root_bridge.json
---

## Summary

Both spring root puzzles solve with real input. The roots read as roots: short braided
rungs across the shaft, a thin braided bridge across the chasm, growing from both sides.

## What was seen

- Shaft: Enraizar from the floor, jump and hold up to grab, climb the web; holding up
  out of its top hops Ivo up, and steering right lands him in the opening. Pressing right
  while still holding on only pushes him into the wall under the opening (his hands stop
  about 16 px short of its floor) - climbing out of the top is the way in.
- Bridge: from the low stone ledge the pulse covers both banks; the strands meet in ~1.5 s;
  Ivo jumps up through the one-way bridge and runs across.

## Found and fixed

The strand from the far bank drew 15 px above the near one (rotation flipped its art);
it is centred by local offset now.

## What this cannot judge

Whether "climb out of the top, then steer" is discoverable to a person; a second web grows
above the opening where the walls face again, which a player holding up will climb into.
