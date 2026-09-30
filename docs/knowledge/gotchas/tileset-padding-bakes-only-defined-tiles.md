---
id: gotchas/tileset-padding-bakes-only-defined-tiles
type: gotcha
title: A TileSet's texture padding only bakes defined tiles, so seasonal bands must be defined even though no cell uses them
status: active
tags: [tileset, seasons, shader, rendering]
related: [architecture/rooms-are-text]
created: 2026-09-23
updated: 2026-09-23
source_files:
  - tools/maps/build_floor_tileset.gd
  - scenes/world/memory/seasonal/seasonal_art.gdshader
---

## Summary

`TileSetAtlasSource.use_texture_padding` (on by default) draws tiles from an internally
generated padded texture that contains ONLY the regions of tiles that exist in the source.
`seasonal_art.gdshader` samples other bands of the same sheet by offsetting UV.y. If only
band 0's tiles are defined, every other band samples transparent padding: under a pulse of
another season the ground simply vanishes (measured: a FREEZE pulse in Downtown left Ivo
running on nothing but the ice).

## Fix

Define the tiles of every band, bare (no collision, no custom data) -
`build_floor_tileset.gd` does. The old inlined TileSets did this by accident (every sheet
cell was a tile); a generated TileSet has to do it on purpose.
