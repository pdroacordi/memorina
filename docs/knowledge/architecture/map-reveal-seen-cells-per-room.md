---
id: architecture/map-reveal-seen-cells-per-room
type: architecture
title: The map reveals what the camera showed - a 64 px bitset per room key in PlayerData, marked from the view rect, drawn as fill runs and inner edges
status: active
tags: [map, reveal, save, camera, ui, draw, bitset]
related: [systems/map, architecture/pause-menu-worldfreeze-reuse, architecture/save-slots-and-the-boot-swap, architecture/the-life-loop-rewinds-by-reloading, architecture/rooms-are-text, systems/life-benches-death, systems/rooms]
created: 2026-10-02
updated: 2026-10-06
source_files:
  - scenes/ui/map/map_grid.gd
  - scenes/ui/map/map_outline.gd
  - scenes/ui/map/map_revealer.gd
  - scenes/ui/map/map_screen.gd
  - scenes/ui/map/map_canvas.gd
  - scenes/world/camera.gd
  - scenes/world/game.gd
  - globals/player_data.gd
  - globals/save_system.gd
---

> **Status: built** (2026-10-06, roadmap UI-04). The current contract is `systems/map`; the Revision below lists where the build differs from this plan.

## Context

The user's decisions (2026-10-02): M / pad LB toggles the map; it does NOT freeze the world;
Ivo cannot act while it is open, but enemies run and can hit him; it opens centred on Ivo with
no player marker, pans with stick/arrows and has zoom steps. It reveals only the parts of each
room that were actually on screen, drawn as the seen area filled, with an ink outline along its
edge. It REWINDS on death like everything since the last bench. Design 02 (UI): Metroid style,
deliberately low detail, never the exact position.

Constraints: rooms are 1920x602 today and will be larger than the screen. Room contents load
lazily, but every `Room` trigger (bounds, `SceneKey`) is always in the tree. The save is
`duplicate_deep`-copied on every commit and rewind, and holds no custom sub-resource scripts
(`the-life-loop-rewinds-by-reloading`).

## Options considered

**Granularity.**
- Whole room on entry (classic Metroid): rejected by the user, who wants only what was on screen.
- 32 px cells (a room-map tile): four times the data of 64 px, and finer than the design wants.
- **64 px cells (chosen)**: 2x2 room tiles. A 640x360 view covers 10x6 cells. A 1920x602 room
  is 30x10 = 300 cells, which is 38 bytes plus a header.
- 128 px: a view is 5x3 cells, so a revealed edge can be off by a third of a screen.

**What counts as seen.** A cell that the view merely overlaps would reveal up to a cell beyond
what was shown. **Chosen: a cell whose CENTRE was inside the view.** The reveal is then never
more than half a cell off.

**Where "on screen" comes from.** A radius around Ivo is not what the screen showed. Area2D or
`VisibleOnScreenNotifier2D` per cell means thousands of nodes. **Chosen: the camera's view rect**
(`GameCamera.view_rect()`, new; the camera is already the one node that converts world to
screen), intersected with the current room's bounds. That is one `Rect2i` of cells per frame,
and work is done only when that range changes.

**Encoding in `PlayerData`.**
- **Chosen: `map_seen: Dictionary[String, PackedByteArray]`**, keyed by the room's `SceneKey`. Each
  value is a bitset in row-major order behind a 4-byte header (cols u16 LE, rows u16 LE). It is a value
  type, so deep copies are independent. It needs no sub-resource script. The header lets a
  resized room keep its cells by (col, row).
- A packed array of seen cell indices costs 4 bytes per cell instead of 1 bit.
- An Image per room puts a Resource inside the save, is heavier and cannot be diffed as text.
- `Dictionary[Vector2i, bool]` makes huge text and a slow copy.

**Rendering.**
- **Chosen: `MapCanvas` (Control) `_draw()` of horizontal fill runs plus boundary edges** from a pure
  `MapOutline`. The geometry is built once per room when the map opens. Panning moves the canvas
  and does not redraw; a zoom step redraws. Edges are drawn as 1 px rects on the INSIDE of the
  boundary, because a 1 px line on an integer coordinate straddles two pixels.
- An ImageTexture per room (1 texel per cell) plus an outline shader means fewer draw commands, but
  the edge width at three zooms inside a 2x menu root is fiddlier. It is the lever to use if the
  draw cost grows.
- Marching-squares polylines would give smooth ink, which is more detail than the design asks for.

**Per room or one world grid.** **Chosen: per room key.** Room bounds do not sit on one shared 64 px
grid (Downtown's shape is at x -403.75). Each room gets its own closed outline, which is the
Metroid room box. Cells are room-local, so a region that moves keeps its map.

## Decision

- `MapGrid` (RefCounted, pure): `CELL_PX := 64`; `dims_for(bounds) -> Vector2i` (ceil);
  `from_bytes(bytes, dims)` (an empty or invalid value gives an empty grid; a different header
  is copied cell by cell where the two overlap); `to_bytes()`; `mark_rect(local_rect) -> bool` (centre rule;
  true only if a bit changed); `is_seen(col, row)`; `is_empty()`.
- `MapOutline` (RefCounted, static): `fill_runs(grid) -> Array[Rect2i]` (one per horizontal run)
  and `edges(grid)`: boundary segments in cell units, merged when collinear, each carrying the side
  its inside is on.
- `MapRevealer` (Node in `World`, PAUSABLE, after `Camera2D` in tree order): `on_room_changed(room)`
  (wired from the new `Game.room_changed`) loads that room's grid from
  `SaveSystem.map_seen(key)`. Each physics frame it marks `view_rect ∩ bounds`, and on a change
  it calls `SaveSystem.set_map_seen(key, grid.to_bytes())` (write-through, so a bench commit
  never misses a cell).
- `MapScreen` (in `Screens`, ALWAYS, 2x menu art) builds the geometry for every room in
  `Room.GROUP` that has data. On `open(centre)` it centres on Ivo's world position, pans by
  `MenuInput.pan` in real seconds, clamped to the seen content, and steps zoom through 1/2/4 pack
  px per cell. Each room's origin is rounded to whole pixels at each zoom.

## Consequences

- The map rewinds with the ledger for free (it is live data, committed at benches).
  `SaveLedger.record_death` must NOT carry `map_seen` into the committed save.
- A `PackedByteArray` inside a Dictionary is a value. `var b := data.map_seen[key]; b[0] = 1`
  changes a copy, so always reassign (`SaveLedger.record_death` does the same with `deaths`).
- `CELL_PX` is part of the save format. Changing it needs a migration that resamples by world position.
- Size is rooms x (4 + cells/8) bytes. A text `.tres` writes a `PackedByteArray` in full. Measure a
  fully explored world; the lever is binary `.res` slot files (one line in `SaveSlots`).
- Rounding each room's position at each zoom can leave 1 px seams between neighbours. This is
  accepted, because every room is outlined on its own.
- Nothing is revealed during a freeze (the revealer is pausable), including a lesson's push-in.
- The map does not redraw while it is open. A knockback that shows new ground while the map is
  up appears the next time it opens.

## Revision (2026-10-06): as built

Built in UI-04, then reviewed (`godot-reviewer`) and playtested (`playtests/2026-10-06-map`). Where the build differs from the Decision above, and why:

- **Cut last cell.** `MapGrid.cells_in(local_rect, room_size)`: a last row or column cut by the room's edge counts by the centre of its part inside the room. With the plain centre rule, row 9 of every 602 px room (centre y 608) could never be seen, because the camera never shows past the room. Found by `map_revealer_test`.
- **Notches.** `MapOutline.notches` and `ink(edges, notches, px)`. Ink drawn inside both edges of an inner corner touches only diagonally, so each notch adds one pixel.
- **Fill runs** also merge downward while the span below matches, for fewer draw calls.
- **Scans read `MapGrid.padded_cells()`**, one byte per cell with an unseen border. Calling `is_seen` per neighbour took 967 ms for 200 rooms of 60x19 cells; the padded scan takes 146 ms. `MapScreen` caches each room's geometry by its bytes and origin, so a reopen rebuilds only rooms that changed.
- **`MapCanvas` is a Node2D, not a Control.** A Control is culled by its own rect, so the whole map vanished whenever the canvas origin left the screen (`gotchas/a-control-is-culled-by-its-own-rect`).
- **Zoom 1/2/4/8 pack px per cell, opening at 4** (the mockup's scale), not 1/2/4. User decision 2026-10-06: "Keep 1/2/4/8, open at 4".
- **Pan:**
  - in pack px per real second (160), so it looks the same on screen at every zoom;
  - each frame's step is capped at 0.05 real seconds;
  - an axis held when the map opens is ignored until it reads zero (`bugs/a-direction-held-when-the-map-opens-pans-it-off-ivo`);
  - the centre clamp is kept: user decision 2026-10-06, "Keep centre clamp".
- **No `open(centre)` argument.** `MapScreen` is a `MenuScreen`; `Game._ready` calls `Screens.set_map_subject(player)`. A new `MenuScreen.can_open()` asks `Player.can_open_map()`: on the floor, alive, not sinking, not climbing or wall-sliding, Memorina sheathed (user decisions 2026-10-06, "Right" and "Refuse").
- **Blocking Ivo.** New `Screens.BLOCKING` with `block_requested` / `unblock_requested`, wired in `game.tscn` to `Player.block_input` / `unblock_input`. Those set `PlayerInput.blocked` and drop the input buffers. `Player.hurt` → `Screens.close_map`.
- **When `room_changed` fires.** `Game.room_changed` is emitted where the frame shows the room, not inside `_enter_room`. At a debug boot onto a bench, one physics step ran before the seat and marked the authored start's view (`bugs/a-debug-boot-reveals-map-cells-ivo-never-saw`).
- **Map files.** `MapRevealer` lives in `scenes/ui/map/` as planned; its node is in `World`, after `Camera2D`.
- **Measured size** (the risk in Consequences): today's world fully explored adds 1.3 KB to the `.tres`. 200 rooms of 3840x1204 px fully explored come to 47 KB as `.tres` and 36 KB as `.res`, so binary slots are not needed.
- **Accepted, as planned:** a grid that rounds up reaches up to 63 px past its room, so rooms stacked vertically may overlap their boxes. Every room is outlined on its own.
