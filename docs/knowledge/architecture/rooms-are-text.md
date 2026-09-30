---
id: architecture/rooms-are-text
type: architecture
title: Rooms are authored as `.room` text maps, parsed once at import and built by RoomMapNode
status: active
tags: [level-design, tilemap, import-plugin, llm-authoring, rooms, enraizar]
related: [gotchas/tileset-padding-bakes-only-defined-tiles, gotchas/lake-hidden-under-a-tilemaplayer-parent]
created: 2026-09-23
updated: 2026-09-23
source_files:
  - addons/room_maps/room_map_importer.gd
  - scenes/world/rooms/maps/room_map_parser.gd
  - scenes/world/rooms/maps/ground_autotile.gd
  - scenes/world/rooms/maps/room_map_node.gd
  - scenes/world/rooms/maps/map_guide.gd
  - resources/world/maps/room_legend.tres
  - docs/maps/README.md
---

## Summary

A room's ground, water and grid-aligned things live in `<room>.room`: an ASCII grid (one
character per 32 px cell), an optional `[water]` layer of the same size, and `[entities]`
JSON params keyed by grid column,row. `addons/room_maps` imports it once into a `RoomMap`
resource with every ground tile resolved by `GroundAutotile`; `RoomMapNode` in the
contents scene builds the ground `TileMapLayer`, one `WaterLayer` per water kind and the
entities. The authoring guide is `docs/maps/README.md`; its legend, entity params and
Ivo's reach are generated from the code and `map_guide_test.gd` fails when they drift.

## Why

- A painted `TileMapLayer` is a base64 `PackedByteArray` in the `.tscn`: no person or LLM
  can read a gap's width from it, diff it meaningfully, or write one. Text can.
- Enraizar needs the MATERIAL of the ground (earth roots, stone does not). A character
  carries it (`#` / `S`); the four copies of an inlined TileSet could not.
- The idea came from `D:\Projects\FAG-orbita` (level `.txt` + `.json`), which parses at
  runtime on every load. Here parsing - and autotiling, the expensive part - happens at
  import, so a load costs the same as the old baked tile data.

## Decisions and trade-offs

- **Water is a second layer**, not characters in the ground grid, because a lake lies OVER
  the ground. Each map water cell becomes 2x2 of the water system's 16 px cells.
- **Out of the map is solid to the left, right and below, open sky above**, so rooms run
  on at their borders and top-row ledges keep their grass. The exporter extended each
  column's floor to the grid's bottom so floors keep their thickness.
- **The autotiler reproduces the paint closely, not exactly**: seams where two separately
  painted blocks touched are merged, and 2-wide column tops use the block corners (near
  identical art). Step corners use the sheet's grass-tuft pieces (4,3)/(5,3), which is what
  the rooms were painted with.
- **Guardians and arenas stay in the contents scene**: a guardian's `arena_path` is a
  NodePath to its sibling `Arena`. Everything grid-aligned goes in the map.
- **Stone is derived, not drawn**: `tools/art/derive_stone_tiles.gd` turns the earth half
  of `floor_tiles.png` into masonry in columns 9-17 of every seasonal band.
- **Tools that load entity scenes run as scenes**, because `-s` SceneTree scripts have no
  autoloads and `Enemy` references `SaveSystem`.
