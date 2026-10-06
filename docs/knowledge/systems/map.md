---
id: systems/map
type: system
title: The map: seen cells per room, the revealer, the outline and the map screen
status: active
tags: [map, reveal, save, camera, ui, draw, bitset, screens]
related: [architecture/map-reveal-seen-cells-per-room, systems/screens, systems/input, systems/life-benches-death, systems/rooms, gotchas/a-control-is-culled-by-its-own-rect, bugs/a-direction-held-when-the-map-opens-pans-it-off-ivo, bugs/a-debug-boot-reveals-map-cells-ivo-never-saw, playtests/2026-10-06-map]
created: 2026-10-06
updated: 2026-10-06
source_files:
  - scenes/ui/map/map_grid.gd
  - scenes/ui/map/map_outline.gd
  - scenes/ui/map/map_revealer.gd
  - scenes/ui/map/map_canvas.gd
  - scenes/ui/map/map_screen.gd
  - scenes/ui/map/map_screen.tscn
  - scenes/world/camera.gd
  - scenes/world/game.gd
  - globals/player_data.gd
  - globals/save_system.gd
---

# The map: seen cells per room, the revealer, the outline and the map screen

**Never break:** The map shows only cells whose centre was on screen, per room `SceneKey`. `MapGrid.CELL_PX` (64) is part of the save. Reassign a `PackedByteArray` in `map_seen`, never edit it in place. The revealer stays pausable, after `Camera2D`, and is armed only by `Game.room_changed`. The canvas is a Node2D.

## Summary

The map (UI-04, design 02 "Mapa") reveals the parts of each room the camera showed, as 64 px cells. It draws them over the dimmed world as a faint fill with a 1 px ink line inside their edge. Ivo can open it only while he stands on the ground with the Memorina sheathed. It never holds the world: Ivo is blocked and can still be hit, and any hit closes it. The cells are live save data, so a bench keeps them and a death forgets them. Plan and options: `architecture/map-reveal-seen-cells-per-room`.

## Data: `MapGrid` and `PlayerData.map_seen`

- `PlayerData.map_seen: Dictionary[String, PackedByteArray]`, keyed by the room's `SceneKey`. Read through `SaveSystem.map_seen(key)` and written with `set_map_seen(key, bytes)`.
- **Bytes:** a 4-byte header (cols u16 LE, rows u16 LE), then the bits in row-major order. Bit `i` is in byte `i >> 3`, mask `1 << (i & 7)`.
- **Dimensions:** `MapGrid.dims_for(bounds)` rounds the room's size up to whole cells. A 1920x602 room is 30x10 cells, and its grid reaches 38 px below the room.
- **Decoding:** `from_bytes(bytes, dims)`. Empty or malformed bytes give an empty grid. A different header keeps the cells both sizes share, by (col, row).
- **Cells count from the top-left of the room's bounds,** so a region that moves keeps its map.
- **Centre rule:** a cell is seen when its centre was inside the view (`cells_in`, `mark_rect`).
- **Cut last cell:** with `room_size`, a last row or column cut by the room's edge counts by the centre of its part inside the room. Without that, row 9 of a 602 px room (centre y 608) could never be seen, because the camera never shows past the room.
- `padded_cells()` returns one byte per cell inside a border of unseen cells. Every `MapOutline` scan reads it.

## Revealing: `MapRevealer`

- A Node under `World`, after `Camera2D` in `game.tscn`, PAUSABLE: nothing is revealed during a freeze or a hold.
- **Arming.** `Game.room_changed(room)` arms it with the room's key, bounds and grid. `Game` emits it where the frame shows the room:
  - after `_enter_room` on a walk-in, behind the black;
  - after a hazard respawn changes the room;
  - after `_arrive`'s seat and `snap()`.
  `_enter_room` itself does not emit, because at a debug boot a physics step runs before the seat (`bugs/a-debug-boot-reveals-map-cells-ivo-never-saw`).
- **Each physics frame** it takes `GameCamera.view_rect()` ∩ bounds, reduces it to a cell range, and returns if the range has not changed.
- **Write-through:** on a new cell it calls `SaveSystem.set_map_seen(key, grid.to_bytes())`, so a bench commit never misses a cell.

## Geometry: `MapOutline`

- `fill_runs(grid)`: horizontal runs in cell units, merged downward while the run below has the same span.
- `edges(grid)`: boundary segments, merged where collinear neighbours have the same inside. Each carries `inside`, the unit step toward the seen side.
- `notches(grid)`: grid points with exactly one unseen cell of four. Ink drawn inside both edges touches only diagonally there, so the notch adds the missing pixel.
- `ink(edges, notches, px)`: 1 px rects on the inside of every edge, plus each notch pixel. At 1 px per cell the ink is the boundary cells themselves.

## Drawing: `MapCanvas` and `MapScreen`

- **Structure.** `map_screen.tscn` is a full-rect `MapScreen` (a `MenuScreen`) with `Dim` (black at 0.65; it dims the HUD too) and `Art` (320x180 at scale 2). Under `Art` sits `Canvas`, a `MapCanvas`.
- **`MapCanvas` is a Node2D.** A Control is culled by its own rect, and the canvas draws far outside it (`gotchas/a-control-is-culled-by-its-own-rect`).
- **Look (style "C ink overlay"):** colours sampled from the approved mockup. Ink is (0.92, 0.90, 0.84). The fill is the same cream at 0.27, drawn first. No frame, no text, no player marker.
- **Pixels:** the canvas sits in pack px with world (0, 0) at its origin. Each room's origin is rounded to a whole pack px at each zoom, and the canvas position is rounded too, so every cell lands on the 2x grid.
- **Zoom:** `CELL_PX_STEPS = [1, 2, 4, 8]` pack px per cell, opening at 4 (`OPEN_STEP`). Each step keeps the centre and re-lays the rects.
- **Opening:**
  - centred on `subject.global_position`, clamped into the seen area;
  - the canvas is not redrawn while the map is open, so cells seen meanwhile appear at the next open.
- **Pan:** `pan_held(MenuInput.pan, real seconds)`.
  - Real seconds come from `Time.get_ticks_usec`, because the world's clock is slowed by a recall or a hit-stop.
  - Each step is capped at `MAX_PAN_SECONDS` (0.05).
  - Speed is `pan_speed` (160 pack px per real second at full tilt), the same on screen at every zoom.
  - An axis already held when the map opens is ignored until it reads zero (`bugs/a-direction-held-when-the-map-opens-pans-it-off-ivo`).
  - The centre is clamped to the seen area's world rect, so at any edge half the screen is empty dimmed world ("Keep centre clamp").
- **Cache:** `MapScreen` keeps each room's `MapCanvas.Patch` with the bytes and origin it was built from, and rebuilds only rooms that changed since the last open.

## Opening and closing (wiring in `systems/screens`)

- **Opening:** M / pad LB. `Screens` asks `MapScreen.can_open()`, which asks `Player.can_open_map()`: on the floor, alive, not sinking, not climbing or wall-sliding, Memorina sheathed. A refused press is not consumed.
- **Closing:** M / LB again, Esc, Start or B. Any hit (`Player.hurt` → `Screens.close_map`) and a death (`Screens.lock`) close it too.
- **While open, Ivo is blocked:**
  - `Player.block_input` sets `PlayerInput.blocked`;
  - it drops the jump, roll, attack (including a combo press) and draw buffers, and any pending sit or stand;
  - he stays physically simulated and hittable.

## Performance and size (measured 2026-10-06)

- Today's world fully explored (9 rooms, 2,990 cells): the slot `.tres` grows from 425 B to 1,746 B.
- 200 rooms of 3840x1204 px (60x19 cells), fully explored: 47,276 B as `.tres`, 36,295 B as `.res`. `duplicate_deep` takes 0.09 ms.
- Geometry for those 200 rooms partly explored: 146 ms at the first open; later opens rebuild only changed rooms. Calling `is_seen` per neighbour took 967 ms, which is why the scans read `padded_cells()`.
- Marking a 10x6 view in 200 grids: 1.8 ms.
- Next step if drawing grows: one texture per room (a texel per cell) with an outline shader.

## User decisions

2026-10-02:
- "Toggle"; "Ground only, hits close"; "World keeps running"; "Centred on Ivo, zoom"; "Seen area, outlined"; "C ink overlay"; "Map rewinds".
- The reveal: "Room outlines, but not entire room. A room can be enourmous. And the map can be enormous as well. So it is needed to know, once the player has gone trhough all the map and thus drawn the map, the whole map cannot fit the screen, so we have to cope nicely with that. also, as a single room can be pretty big, the whole room should not be drawn on the map, but rather only the parts of the room the player saw on screen".

2026-10-06:
- "Refuse": no map with the Memorina drawn.
- "Right": the ground rule as built. On the floor, alive, not sinking. It opens while sitting, mid-roll and mid-swing, and is refused while climbing or in the air.
- "Keep 1/2/4/8, open at 4".
- "Keep centre clamp".
- "Dim it too": the map's dim also dims the HUD.

## Tests and timelines

- Suites:
  - `tests/scenes/ui/map/map_grid_test.gd`, `map_outline_test.gd`, `map_revealer_test.gd`, `map_screen_test.gd`;
  - `tests/scenes/ui/screens/screens_map_test.gd`: a real Ivo on a floor; refused in the air or with the Memorina drawn; buffers dropped, with a control test;
  - `tests/globals/save_ledger_test.gd` (rewind and rest) and `player_data_test.gd` (round-trip, old saves load with no map);
  - `tests/scenes/characters/ivo/player_input_test.gd` (blocked).
- Windowed timelines: `tools/playtest/scripts/map_*.json`, run with `APPDATA` redirected. The runner's `log` prints the open screen, the map centre and zoom, and the seen cells per room.
