---
id: systems/backdrops
type: system
title: Backdrops - parallax layers that work vertically, anchored to the room's horizon
status: active
tags: [backdrop, background, parallax2d, camera, seasonal-art, greyhush, shader, rooms]
related: [architecture/vertical-backdrops, gotchas/parallax2d-ignores-its-parents-offset, systems/seasonal-art, systems/greyhush, systems/rooms]
created: 2026-10-08
updated: 2026-10-09
source_files:
  - scenes/world/environment/backdrop/backdrop.gd
  - scenes/world/environment/backdrop/backdrop_math.gd
  - scenes/world/environment/backdrop/backdrop_layer.gdshader
  - resources/world/backdrops/backdrop_layer.gd
  - resources/world/backdrops/backdrop_set.gd
  - resources/world/backdrops/pine_woods.tres
---

# Backdrops

**Never break:** a layer is placed only by `BackdropMath`; the anchor is the room's global position plus `horizon_y`; a fill past the strip reads the sheet's own edge row, never a colour. `art_row`/`art_col` in `BackdropMath` and `backdrop_layer.gdshader` are one mapping in two languages: change both.

Design 04 section 6 ("Fundos verticais"), WORLD-06, which also fixes WORLD-04. Plan and options: `architecture/vertical-backdrops`.

- **Draw order.** `Backdrop.Z` is -30: behind WORLD-07's `[back]` walls (-20) and props (-10) (`systems/props`).
- **Authoring.** A room's contents scene has one `Backdrop` node (first child of `Contents`) with a `BackdropSet` and `horizon_y`: the room's horizon, px below the node. A set is data: its layers far to near (`BackdropLayer`: stacked sheet, `band_count`, `band_of_season`, `scroll_scale` per axis, `horizon_row`, `fill_above`/`fill_below` NONE/EDGE/REPEAT, `repeat_x`, haze `distance`) and `horizon_screen_y`, the eye level in game px.
- **The model, per axis.** At the reference camera (`BackdropMath.reference_centre`: the camera that shows the anchor's horizon at `horizon_screen_y`) every layer stands where it was authored. Away from it a layer's anchor moves by `(camera - reference) * (1 - scroll)`. So a far layer (`scroll` near 0) keeps its horizon at eye level whatever the camera's height, and a layer at 1 is pinned to the world.
- **Built nodes.** `Backdrop.refresh()` builds `LayerN` (`Parallax2D`, `scroll_scale` from the layer, `scroll_offset` from `BackdropMath.scroll_offset` against the room's global position) holding `Art`, a `MeshInstance2D` `QuadMesh` sized to `BackdropMath.cover_rect` (what the room's camera can show at zoom 1 or more, plus 32 px) and clipped by `clip_to_fills`. The built nodes are unowned and never saved. Without a `Room` above it (the editor, a contents scene opened alone) it uses a fixed preview rect.
- **Clipped to its room** (2026-10-09): the current room's neighbours run and draw (`systems/rooms`), and a parallax layer slides past its room's edge, so `Backdrop` sets `room_rect` (the room's world bounds) and the shader discards every pixel drawn outside it (`MODEL_MATRIX * VERTEX` carries the `Parallax2D` scroll). Without it a neighbour's layers drew over the current view and popped at every crossing (`bugs/a-running-neighbour-rooms-backdrop-draws-over-the-current-room`). No `Room` (editor preview): no clip.
- **The shader** picks each pixel's texel from its layer-local position (`VERTEX + quad_position`) with `texelFetch`: EDGE repeats the strip's first or last row, REPEAT wraps, NONE is transparent. Season from the mask (`gh_season_at`, `gh_band_for` in `seasonal_common.gdshaderinc`, shared with `seasonal_art.gdshader`), haze from `distance` exactly as `systems/seasonal-art`. No `TIME`, no `FRAGCOORD`.
- **Measured.** `backdrop_test` drives a real `Camera2D`: each `Parallax2D` lands where the model says at zoom 1 and at 1.5 (the Memorina draw), and a room at (12160, 6000) shows the same picture as one at the origin.
- **Art contract** (every biome set): `architecture/vertical-backdrops`, "Art contract". Every EDGE row is one colour per band (`backdrop_set_test`). `background_layer_3`'s bottom row was flattened to its dominant colour for this (2026-10-08); its season sources too, so `tools/stack_seasonal_sheets.gd` keeps it.
- **Today's sets.** `pine_woods.tres`, the pack's forest, is on the eight trial rooms (`horizon_y` -53: 53 px above their floor) and, as a placeholder, on the 31 new-world surface rooms (`horizon_y` 53 px above the room's bottom floor). Underground rooms and interiors have none until their biome sets (WORLD-07 and the style boards). The title keeps its own autoscrolling `Parallax2D`.
