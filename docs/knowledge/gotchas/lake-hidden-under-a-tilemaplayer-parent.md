---
id: gotchas/lake-hidden-under-a-tilemaplayer-parent
type: gotcha
title: Water parented under the ground's TileMapLayer stopped drawing in front of it; build it as a sibling
status: active
tags: [tilemaplayer, water, rendering, scene-tree]
related: [architecture/rooms-are-text, architecture/water-is-world-art-reflecting-two-passes]
created: 2026-09-23
updated: 2026-09-23
source_files:
  - scenes/world/rooms/maps/room_map_node.gd
---

## Summary

The first `RoomMapLayer` was the ground TileMapLayer itself (carrying the seasonal art
material) and added the water layers as its children. The Downtown lake - a `WaterQuad` at
absolute z 50, which should draw over everything at z 0 - no longer showed at all, though
the body was in the tree, visible, and correctly placed. Moving the ground into its own
child TileMapLayer and building the water layers and entities as its SIBLINGS (the
arrangement the painted scenes had) brought it back, pixel for pixel.

The exact engine cause was not isolated (candidates: the parent's material, or the lake's
screen-texture read interacting with the TileMapLayer's own rendering). The rule that
holds: do not parent world drawables under a TileMapLayer; give the tiles their own node.
