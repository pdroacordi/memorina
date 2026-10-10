---
id: architecture/vertical-backdrops
type: architecture
title: Backdrops that work vertically - a Backdrop node builds one Parallax2D per BackdropSet layer, anchored to its room's horizon, with edge and repeat fills done in the shader (WORLD-06, absorbs WORLD-04)
status: active
tags: [backdrop, background, parallax2d, camera, seasonal-art, greyhush, shader, rooms, art-contract, plan, world-06, world-04]
related: [gotchas/parallax2d-ignores-its-parents-offset, bugs/the-winter-trial-tree-layers-end-in-vertical-cuts-over-the-squall-puzzle, systems/seasonal-art, systems/greyhush, systems/songs-and-the-memorina, systems/rooms, systems/art-pipeline, bugs/creature-pass-frozen-transform-floats-bodies, bugs/camera-zoom-out-shows-past-room-bounds, gotchas/duplicate-copies-script-built-unowned-children, bugs/room-map-node-rebuild-renames-and-doubles-its-children, gotchas/glsl-gdscript-math-must-be-duplicated, gotchas/screen-texture-copy-scope, gotchas/logger-log-error-also-receives-warnings, architecture/rooms-are-text, architecture/backdrop-seams]
created: 2026-10-08
updated: 2026-10-10
source_files:
  - scenes/world/environment/backdrop/backdrop.gd
  - scenes/world/environment/backdrop/backdrop_math.gd
  - scenes/world/environment/backdrop/backdrop_layer.gdshader
  - resources/world/backdrops/backdrop_set.gd
  - resources/world/backdrops/backdrop_layer.gd
  - scenes/world/memory/seasonal/seasonal_common.gdshaderinc
  - scenes/world/rooms/room.gd
  - tools/stack_seasonal_sheets.gd
---

> **Status: BUILT** (2026-10-08, WORLD-06; `systems/backdrops`). Differences from the plan: each layer's art is a `MeshInstance2D` `QuadMesh` whose shader reads the texel from `VERTEX + quad_position` (the plan's own fallback for out-of-range Sprite2D regions), not a `Sprite2D`; `BackdropMath.reference` is `reference_centre` (`RefCounted` owns `reference()`); the editor horizon line is not drawn; the art-tooling changes (`--set`, `seasons:`, `--tile`) come with the biome style boards.

## Summary

Design 04 §6 ("Fundos verticais"): each layer has its own horizontal and vertical parallax and
an anchor height (the room's horizon). Above the art the sky continues, below it the earth
continues. Underground sets repeat on both axes, and a tall room that crosses the horizon shows sky
above and strata below. One `Backdrop` node per room contents reads a `BackdropSet` resource and
builds one `Parallax2D` + `Sprite2D` per layer. The per-room data is the set and `horizon_y`.
`scroll_offset` is computed from the room's global position at ready, which fixes WORLD-04 for every
room. Edge and repeat fills are row arithmetic in a seasonal shader, so they change season under a
pulse and dissolve into the haze like the art.

## Context

- Today, each of the 12 `*_contents.tscn` hand-places five `Parallax2D` (`scroll_scale.x`
  0.1..0.8, `.y` = 1) with a `Sprite2D` on band 0 (346 px) of a 1024x1038 sheet. The sky is
  scaled 2.16x2.55. Each layer has its own `background_layer_N_material.tres`, and those differ
  only in `distance`. With `.y = 1` the art is pinned to the world, so a tall view shows the clear
  colour above and below it.
- `Parallax2D` sets its local position to `(C - half_view) * (1 - s) + scroll_offset` from the
  camera's GLOBAL centre `C`, so under a region at x 7200 the far layers are off screen
  (`gotchas/parallax2d-ignores-its-parents-offset`). Rooms are also offset inside their region
  (`EmptyHouse` at 2560 inside `TrialsSolstice` at 9600).
- Regions without `repeat_size` end in vertical cuts (`bugs/the-winter-trial-tree-layers-...`).
- The camera is clamped to `Room.get_bounds()`. Zoom is always 1 or more: the Memorina draw
  is 1.5 and the lesson is 1.15. A zoom tween runs under the pause, and `Camera2D.set_zoom()` calls
  its `_update_scroll()` directly.

## The model (per axis, independent)

The anchor `A` is `Backdrop.global_position + (0, horizon_y)`. The reference camera centre is
`R = (A.x, A.y + 180 - horizon_screen_y)`. A layer's anchor point (art column 0, row
`horizon_row`) is drawn at world `L = A + (C - R) * (1 - s)`, where `C` is the screen centre.

Read on screen: the layer's horizon sits at `horizon_screen_y - s_y * (C.y - R.y)`. That blends
two places by `s_y`. At `s_y` 0 the horizon is at eye level (`horizon_screen_y`, which the
set owns). At `s_y` 1 it is the room's horizon height (`horizon_y`, which the room owns).
Horizontally, `A.x` is the room's own origin, so the art's phase never depends on where a
region or room is placed. Mapped onto `Parallax2D`:
`scroll_offset = A - P + (half_view - R) * (1 - s)`, with `P` = the Parallax2D's parent global
position and `half_view` = (320, 180). This is constant per room, so it is computed once at ready.

## Options considered

- **Positioning.**
  - (a) **`Parallax2D`, configured at ready (chosen).** Camera2D's `_update_scroll` calls it
    synchronously on every path: a physics move, and `set_zoom` under a paused tree. So it has no
    frame lag, adds no `process_mode`, and adds nothing to the pause-mode map.
  - (b) A script that positions layers in `_process` from `get_canvas_transform()`. Rejected.
    It must run after the camera's internal process and be ALWAYS. A pausable camera mirror is
    exactly `bugs/creature-pass-frozen-transform-floats-bodies`.
  - (c) A shader only: one quad that maps world position to art texel from the camera centre.
    Rejected. It needs the camera centre in the shader (`CANVAS_MATRIX` under `canvas_items`
    stretch is unverified, and the water work avoided it with derivatives), and it still needs a
    quad sized to the room.
- **`Parallax2D` features.** `repeat_size`/`repeat_times` are rejected. They repeat in both
  directions or neither, cannot extend an edge row, draw extra copies, and would be a second place
  that decides the phase. `limit_begin/end` are not needed because the camera clamps itself.
  `ignore_camera_scroll` is used only for the editor preview. `scroll_offset` carries the anchor.
- **Coverage.** Each layer's sprite rect is sized at ready to the layer-local span the room's
  camera can show: `BackdropMath.cover_rect` over the bounds, zoom 1 or more, plus a 32 px margin
  for shake and `bugs/camera-zoom-out-shows-past-room-bounds`. Its width is
  `s * room + 640 + 64`. It is one quad, and only on-screen fragments are shaded. Canvas culling
  uses the sprite's rect, which is the full coverage.
- **Filling past the art.**
  - (a) **Clamp to the strip's edge row in the shader (chosen).** The fill comes from the same
    sheet, so it swaps season per pixel under a pulse and takes `distance` haze.
  - (b) A `ColorRect` inside the Parallax2D. Rejected: it would need a colour per season and
    would not read the season mask.
  - (c) A gradient. Rejected: a gradient belongs inside the art, and it is off-palette.
  - (d) A separate extension strip. Rejected: it is covered by REPEAT and the cap-plus-tile pair
    below.
- **Where the per-room data lives.**
  - (a) **A `Backdrop` node in the contents scene (chosen).** Backgrounds and `ground_material`
    already live there.
  - (b) A `[backdrop]` section in `.room`. Rejected: it couples the importer to rendering, forces
    32 px granularity and a `FORMAT_VERSION` bump, and `rooms-are-text` covers ground and
    entities, not rendering.
  - (c) The set on `Region`. Rejected: underground rooms inside a surface region need their own set.
- **Materials.** One `.tres` per layer is replaced by one `ShaderMaterial` per layer that
  `Backdrop` builds from the layer's data. That is still one draw per layer.

## Decision

- **`BackdropLayer extends Resource`** (`resources/world/backdrops/backdrop_layer.gd`):
  - `enum Fill { NONE, EDGE, REPEAT }`.
  - Exports:
    - `texture: Texture2D` (a stacked sheet).
    - `band_count: int = 3`.
    - `band_of_season: Vector4i = (2, 0, 1, 0)` (in `Enums.Season` order; must agree with
      `stack_seasonal_sheets.gd` BANDS).
    - `scroll_scale: Vector2` (0..1 each; 0 is screen-fixed, 1 moves with the world).
    - `horizon_row: int` (band-local art row placed on the horizon; negative puts the whole
      strip below it).
    - `fill_above: Fill = NONE`, `fill_below: Fill = EDGE`.
    - `repeat_x: bool = true`.
    - `distance: float = 0.0` (0..1, haze weight, as in `systems/seasonal-art`).
  - `strip_size() -> Vector2i` and `problems() -> PackedStringArray`.
- **`BackdropSet extends Resource`**: `layers: Array[BackdropLayer]` (far to near = draw order,
  `scroll_scale.x` non-decreasing), `horizon_screen_y: float = 180.0` (game px from the frame
  top; eye level, where a layer at `s_y` 0 draws its horizon), and `problems()`.
- **`@tool class_name Backdrop extends Node2D`** (`scenes/world/environment/backdrop/`):
  - Exports: `backdrop_set: BackdropSet`, and `horizon_y: float` (px, relative to this node).
  - `_ready` → `_build()`. It removes existing children first with `remove_child` + `queue_free`
    (`gotchas/duplicate-copies-script-built-unowned-children`,
    `bugs/room-map-node-rebuild-renames-...`). The built nodes are unowned and never saved.
  - Bounds come from `Room.of(self)`, a new static on `room.gd` that walks up to the nearest
    `Room`. Without a Room (the editor, or a smoke run of a contents scene alone) it uses a fixed
    preview rect, silently: the smoke test fails on warnings.
  - Each layer is seeded with `screen_offset` from `get_viewport().get_camera_2d()`, so it is
    right before the camera's next update.
  - In the editor, each layer gets `ignore_camera_scroll = true` and `scroll_offset = (0, horizon_y)`
    (the reference pose), and a horizon line is drawn.
  - Rebuilds when `backdrop_set` is set or emits `changed`, and on `refresh()`.
  - Tree: `Backdrop / LayerN (Parallax2D) / Art (Sprite2D, centered = false,
    region = cover + (0, horizon_row))`. It is the first child of Contents and stays at z 0.
- **`BackdropMath extends RefCounted`**, static:
  - `reference(anchor, horizon_screen_y, half_view)`
  - `anchor_position(anchor, reference, camera_centre, scroll)`
  - `scroll_offset(anchor, reference, parent_global, scroll, half_view)`
  - `cover_rect(bounds, anchor, reference, scroll, half_view, margin)`: integer-aligned.
  - `clip_to_fills(cover, strip, fill_above, fill_below, repeat_x)`: trims NONE sides, which saves
    fragments.
  - `art_row(row, strip_h, fill_above, fill_below) -> int` and `art_col(col, strip_w, repeat_x)`:
    -1 means transparent. The GDScript twin of the shader's mapping, so a change to one changes both
    (`gotchas/glsl-gdscript-math-must-be-duplicated`).
- **`backdrop_layer.gdshader`**:
  - Art coordinates are `floor(UV * textureSize)`. The region is band-local, so rows can be
    negative or reach past `strip_h`.
  - `art_row`/`art_col` pick the texel, and `texelFetch` reads it at `band * strip_h + row`, with
    no sampler wrap and no half-texel clamp.
  - Modulate is carried as a varying (`systems/seasonal-art`).
  - The season comes from `gh_season_at(SCREEN_UV)`, and the haze is the existing `distance` term.
  - No `TIME`, no `FRAGCOORD`, no dither (`systems/greyhush`).
  - `band_for` moves into `seasonal_common.gdshaderinc` as `gh_band_for`, and
    `seasonal_art.gdshader` calls it with no behaviour change.
- **Zoom** is a focal zoom about the screen centre. `Camera2D` passes `centre - viewport/2`
  (unzoomed), so every layer is magnified equally and keeps its offset. `backdrop_test` must
  confirm this at zoom 1.5 before the migration (see Risks).
- **Underground**: every layer is `REPEAT`/`REPEAT` with `repeat_x`, so the strips tile
  infinitely on one quad. **Crossing rooms need no special case**: a surface set may also list
  below-horizon layers, a cap (`NONE`/`NONE`, ragged top) and a tile (`NONE`/`REPEAT`, its
  `horizon_row` equal to the cap's minus the cap's height). A room whose view never reaches that
  depth never shows them.

## Migration (the existing art is the first set)

- `resources/world/backdrops/pine_woods.tres`, starting values:

  | Layer | Sheet | scroll | distance | fills |
  |---|---|---|---|---|
  | Sky | background_layer_5 | (0.1, 0.05) | 1.0 | EDGE / EDGE |
  | Mountains | background_layer_4 | (0.2, 0.1) | 0.85 | NONE / EDGE |
  | Deeper trees | background_layer_3 | (0.4, 0.2) | 0.6 | NONE / EDGE |
  | Deep trees | background_layer_2 | (0.6, 0.3) | 0.35 | NONE / EDGE |
  | Front trees | background_layer_1 | (0.8, 0.4) | 0.15 | NONE / EDGE |

  - Layers 1-4 share `horizon_row = B`, the first fully opaque row of layer 1's band 0
    (about 245, to be measured). So at the reference camera they stand as they do today.
  - The sky's `horizon_row = horizon_screen_y`, so its top row meets the frame top at the reference
    camera. Its 2.16x2.55 scale is dropped because the world is 1x (04 §6). The top row's EDGE
    fill continues the gradient's zenith.
- In all 12 contents scenes, the five Parallax2D are replaced with one `Backdrop`:
  `horizon_y = -282 + B`, because every layer was centred at y -109. `horizon_screen_y` is chosen
  so that the reference camera is the one framing Ivo on the main floor (about 191 with the
  floor at y 0 and framing -48), and it is measured in the playtest.
- Delete `background_layer_{1..5}_material.tres`. The title (`title.tscn`) is untouched. It keeps
  its own autoscrolling Parallax2D on band 0 with `title_grey_material`, so the legacy sheets stay
  at their paths.
- `stack_seasonal_sheets.gd` gains `--set=<name>`:
  `assets/sprites/world/background/<set>/<season>/layer_<n>.png` is stacked into
  `.../<set>/layer_<n>.png`, with layer 1 nearest. With no flag it keeps today's legacy run.

## Tests (gdUnit4, `--ignoreHeadlessMode`)

- `tests/scenes/world/environment/backdrop/backdrop_math_test.gd`:
  - A camera at the reference returns the anchor.
  - `s` 1 is pinned to the world for any camera.
  - `s` 0 keeps the horizon at `horizon_screen_y` for any camera y.
  - The axes are independent.
  - `scroll_offset` fed through `(C - half) * (1 - s) + so + P` equals `anchor_position` with
    the parent at (12160, 6000) and at the origin (the WORLD-04 regression).
  - Moving the parent and the anchor together leaves the screen output unchanged.
  - `cover_rect` contains the visible span with the camera at every bounds corner, at zoom 1 and
    1.5, including a room smaller than the view, and is integer-aligned.
  - `clip_to_fills` handles NONE, EDGE, REPEAT and `repeat_x` false.
  - `art_row`/`art_col` cover rows inside the strip, -1, `strip_h`, -3*`strip_h`-1 and negative
    columns.
- `tests/scenes/world/environment/backdrop/backdrop_test.gd` (a Room built in code, a current
  Camera2D):
  - The layer count, order and `scroll_scale` match the set.
  - The Parallax2D global positions equal `BackdropMath` after a frame, at zoom 1 and 1.5.
  - The output relative to the screen is identical for the room at the origin and at (12160, 6000).
  - With no Room it builds without warnings.
  - Setting the set twice leaves one set of children.
- `tests/resources/world/backdrops/backdrop_set_test.gd`:
  - Every `.tres` has no `problems()`: the height divides by `band_count`, scroll is in 0..1,
    `.x` is non-decreasing.
  - Every EDGE row (top row for `fill_above`, bottom row for `fill_below`) is one exact colour
    per band.
- A scan test: every `*_contents.tscn` has one `Backdrop` with a set and no `Parallax2D`.

## Files

- **Create**:
  - `backdrop.gd`, `backdrop_math.gd` and `backdrop_layer.gdshader` in
    `scenes/world/environment/backdrop/`.
  - `backdrop_layer.gd`, `backdrop_set.gd` and `pine_woods.tres` in `resources/world/backdrops/`.
  - The three suites above.
  - `docs/knowledge/systems/backdrops.md` and its `CLAUDE.md` row (never break: "A layer is
    placed only by `BackdropMath`; the anchor is the room's global position; fills read the
    sheet, never a colour").
- **Change**:
  - `seasonal_common.gdshaderinc` and `seasonal_art.gdshader` (`gh_band_for`).
  - `room.gd` (`Room.of`).
  - The 12 contents scenes.
  - `stack_seasonal_sheets.gd`.
  - `systems/seasonal-art` (the backgrounds paragraph: `distance` now lives on `BackdropLayer`).
  - Pointers in `gotchas/parallax2d-ignores-its-parents-offset` and the winter-cuts bug.
  - Roadmap WORLD-04 and WORLD-06.
- **Delete**: the five `background_layer_N_material.tres`.
- **Art tooling**, before any biome art is generated, and possibly its own item:
  - `ArtPrompt` gains `seasons:` and a `{season}` token in `target`.
  - `process_image.gd` gains `--tile`: fit by one factor and crop the excess (no bottom-centre
    placement, no stretch), a key only for transparent layers, and a wrap preview of two copies
    side by side for the look step.
  - The prompts README gains a backdrop section.
  - `extract_palette.gd` lists the new sheets.

## Art contract for backdrop layers

- **Density and size.** 1x (04 §6), palette-snapped (`tools/art/palette.json`), alpha 0 or 255
  only. Each season is one source PNG, and three bands stack spring / autumn / winter top to
  bottom. The silhouette is the same drawing in every band ("the same drawing repeated",
  `systems/seasonal-art`). Buildings and interiors use one band. Sizes are multiples of 32.
- **Horizontal tiling.** Every layer with `repeat_x` tiles seamlessly, with column W-1 running
  into column 0, and has no vertical cut anywhere. Surface strips are **1024 px wide** (more than
  the 640 px view, so no repeat shows within one screen).
- **Sky** (farthest, `s` about 0.05-0.1, `distance` 1): opaque, 1024x384.
  - Its **top row is one flat colour** (the zenith, EDGE above) and its **bottom row is one flat
    colour** (EDGE below).
  - Any gradient is stepped in palette colours inside the strip.
  - No cloud touches the top or bottom 16 rows.
- **Silhouette layers** (mountains, hills, tree lines, crater rims, cliffs; `NONE` above,
  `EDGE` below): 1024x384.
  - The **top row is fully transparent**.
  - Opaque from the silhouette's base down, and the **bottom 16 rows are one flat colour per band**
    (the layer's earth, which continues below).
  - The contract states the `horizon_row` (the silhouette's base line).
  - Far layers are flat and low-frequency, with lighter values and few colours: emptiness is
    low-frequency, and the haze dissolves them. Nearer layers carry more detail, but no
    single-pixel noise.
- **Strata pair** (below the horizon in crossing rooms):
  - The **cap** is 1024x128 with a ragged transparent top. Its bottom rows run into the tile.
  - The **tile** is 1024x256, opaque, and seamless on both axes (row 255 runs into row 0).
- **Underground layers** (caves, ice caves, columnar basalt; `REPEAT` both ways): 512x512, and
  every layer is seamless on both axes.
  - The far wall is opaque.
  - Nearer layers are transparent silhouettes (columns, hanging ice), and no feature is cut at a
    wrap row or column.
- **Interiors**: one opaque wall strip of 256x256, seamless on both axes, one band, at `s` (1, 1).
  It sits behind WORLD-07's `[back]` layer.
- **Static.** No layer animates. A turning windmill or drifting smoke is a WORLD-08 prop on the
  memory clock.
- **Per biome (04 §6):**
  - Village: sky, northern mountains, hills with fields.
  - Threshold: sky with mist, an empty plain, and a low horizon (a larger `horizon_screen_y`).
  - Frost Edge: sky, the frozen sea, cliffs.
  - Spring Woods: sky, trunks in layers, canopies. Underground: earth caves.
  - Frozen Lake: snowy mountains, the lake. Underground: ice caves.
  - Orchards: windy sky, hills with (static) windmills, cliffs.
  - Caldera: crater walls open to the sky. A wall cap plus a REPEAT tile carries a 2000 px room.
    Underground: columnar basalt.
- **Paths.** Sources go to `assets/sprites/world/background/<set>/<season>/layer_<n>.png`, and
  the stacked sheet to `.../<set>/layer_<n>.png`. Credit each sheet in `CREDITS.md`.

## Consequences and risks

- **Zoom pivot.** The zoom pivot depends on `Camera2D` passing an unzoomed `centre - viewport/2`.
  If `backdrop_test` shows a top-left pivot instead, layers drift during the 1.5 zoom. The
  fallback is to recompute `scroll_offset` from the zoom, which needs a zoom signal from
  `GameCamera`.
- **Negative `region_rect` origins** on a Sprite2D must render. If they do not, pass the art
  origin as a uniform and keep the region at (0, 0).
- **Vertical parallax moves the trees' opaque bases.** The wall-of-water playtest's "flat dark
  backdrop inside the pocket" is probably that base. Recheck it in the WORLD-06 playtest.
- **The sky changes look** (no stretch). The current rooms look different at the top of tall
  views. Playtest each trial at its x, with peek up and down, the Memorina zoom, a lesson (F9) and
  a pulse edge across the fills.
- **Legacy art.** If a legacy EDGE row is not one colour, `backdrop_set_test` fails. Set that
  side to NONE, or fix the row.
- **No new autoload, no new ALWAYS node, no user-facing strings.** `problems()` messages are
  developer diagnostics in English, not `tr()` keys.

## Revision (2026-10-10, BUILT in WORLD-22)

`architecture/backdrop-seams` plans changes to three points above. The Decision above stays
current until it is built.

- **Horizontal anchor.** "A.x is the room's own origin" holds only on an axis where the art has
  an edge. On an axis where a layer repeats (`repeat_x`; REPEAT both above and below), the anchor is
  world 0. Today two rooms of one set draw a layer `dx * scroll.x mod strip_w` px apart at their
  shared edge; with world phase they draw identical pixels. The WORLD-04 tests that pin a
  room-relative phase are rewritten. Every layer stays on screen, because repeating quads cover
  any x.
- **Clip.** The `room_rect` discard becomes seam ownership. Each pixel within `SEAM_BAND / 2` of a
  room edge is drawn by the room that holds the pixel moved by a Bayer jitter. This is the shader's
  first dither ("no dither" above no longer holds).
- **Art density** is 2x, not 1x ("One 2x pixel density", user, 2026-10-10, `systems/art-pipeline`).
  Sheet sizes stay in game px, and every art pixel is a 2x2 block.
