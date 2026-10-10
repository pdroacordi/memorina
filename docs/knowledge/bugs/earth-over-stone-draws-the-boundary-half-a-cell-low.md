---
id: bugs/earth-over-stone-draws-the-boundary-half-a-cell-low
type: bug
title: Where earth sits on stone, the earth's underlay draws over the top 16 px of the stone cells, so the drawn boundary is half a cell below the real one
status: open
severity: low
tags: [tiles, dual-grid, biome-tilesets, roots, legibility, world-07]
related: [architecture/biome-tilesets, bugs/stone-under-earth-draws-a-seasonal-lip-inside-the-ground, systems/roots-and-climbing]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/rooms/maps/ground_autotile.gd
  - scenes/world/rooms/maps/room_map_node.gd
---

## Summary

The fix for `bugs/stone-under-earth-draws-a-seasonal-lip-inside-the-ground` leaves a stone corner that
has an earlier look (earth) directly above it to the earth's underlay. The earth draws the whole
display tile, so on terraces col 36 the stone starts at world y -1296 instead of its cell top -1312,
and the root-caves column's top is 16 px below its cell. Measured by the WORLD-07 legacy playtest
(`playtests/2026-10-10-world07-legacy-tiles`, re-shoot).

## Impact

Inside solid ground it reads cleanly. On an exposed side face, 16 px of a cell that `ground_at()`
calls STONE is drawn as earth, against 02 §7.1 ("o material diz ao jogador onde a canção serve"):
Enraizar does not grow from that strip.

## Cause

A display tile can only be drawn whole per look; the 16-tile Wang set has no "solid, but another
material" corner, so a stone tile under earth either draws a lipped top (the old bug) or nothing.

## Suggested fix

Each look draws only its own quadrants, with a shape that treats another solid look as solid where
it should not show an edge:
- shape mask: the corners that are solid for the edges (any look above a later look; the current
  rule elsewhere, so stone on earth keeps its rounded feet);
- draw mask: the corners that are this look;
- `BiomeTileset.tile_set()` derives the extra tiles in code from the 16 Wang tiles (the shape
  tile with the other quadrants cleared), so the art contract does not change.
