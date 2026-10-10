---
id: architecture/generated-grass
type: architecture
title: Generated grass - blades drawn on the 2x art grid by one shader per surface run, bent by a per-segment spring field that holds below 0.2 memory, placed from the map's exposed tops when the room is built (WORLD-23)
status: active
tags: [grass, blades, shader, spring, memory-clock, stopped-time, greyhush, seasonal-art, dual-grid, room-map, foreground, characters, plan, world-23]
related: [systems/props, systems/greyhush, systems/seasonal-art, systems/rooms, systems/water, systems/foreground, systems/art-pipeline, architecture/biome-tilesets, architecture/props-and-ambient-life, architecture/memory-gated-height-field, architecture/foreground-layer, architecture/water-is-world-art-reflecting-two-passes, bugs/lake-glints-shear-at-column-seams, bugs/a-rooms-ground-art-hangs-into-the-room-below-at-a-mismatched-seam, bugs/a-neighbour-room-in-another-region-runs-on-the-current-regions-memory, gotchas/import-plugin-output-is-stale-when-its-logic-changes, gotchas/a-tool-script-cannot-call-methods-on-a-non-tool-resource, gotchas/an-explicit-process-mode-escapes-a-disabled-ancestor, gotchas/glsl-gdscript-math-must-be-duplicated]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/environment/grass/
  - resources/world/grass/
  - resources/world/tiles/biome_tileset.gd
  - scenes/world/rooms/maps/room_map_node.gd
  - scenes/world/environment/props/ambient_math.gd
  - tools/art/wang_sheet.gd
  - tools/art/assemble_tile_sheet.gd
  - tools/art/tiles/village_earth.json
  - tools/art/tiles/village_stone.json
---

> **Status: BUILT** (2026-10-10, roadmap WORLD-23). Design 04 §1 "Grama gerada". The user's request: "What if the grass was generated instead of pixels? it moves when int contact with the player." Their choice: "Freeze in the grey (Recommended)". Deviations:
> - **No separate texture class.** `GrassField` keeps one `ImageTexture` per run itself, instead of a `GrassTexture` class.
> - **No map-guide grass column.**
> - **No `grass_field_test`** yet; the playtest covers it.
> - **Segments.** Each blade takes its nearest segment's bend; there is no interpolation.
> - **Top row.** The map's top row grows no grass: its blades would stand above the room and be clipped.
> - **Clip.** The clip gives way sideways by a blade's lean, so tips can cross room seams.
> - **Off screen.** A run off screen does not advance.
> - **Cost.** The review measured 0.51 ms per physics frame with 3 street rooms visible. After that measurement, the per-frame `to_global` calls, the allocations and the off-screen stepping were removed.
> - **Wind is left out,** as recommended. The question was not put to the user again.
> - **Dirt verges.** The village street is cobbles, whose grass is only a short moss fringe. The east gate's outer half and the lane's west end became earth, so the road out of the village has a grass verge.

## Summary

Grass grows on every exposed top of a look whose biome gives it a `GrassLook`. `GrassPlacement` (pure) derives it from the `RoomMap` when `RoomMapNode` builds, so nothing is authored and nothing is imported. One `GrassField` per room steps a spring per 4 px segment. A spring is pushed by nearby `Character.CHARACTERS_GROUP` bodies and runs at `delta * memory` of its cell. Below 0.2 memory its bend and velocity hold exactly. Sway comes from per-cell phases on the same clock. One quad per run per row is drawn by `grass_blades.gdshader`, which draws one-art-pixel blades on the world-anchored 2x grid from a per-segment data texture. The shader never reads `TIME` or `FRAGCOORD` and draws no anti-aliasing. It picks the season band per pixel from the season mask: spring/summer green, autumn dry, winter none. The back row is world art: greyed by the greyhush and reflected by water. A sparse, short front row is drawn in `ForegroundPass`, over Ivo's feet. The tile sheets' spring lip becomes a short turf.

## Context

- Grey is stopped time: a gesture caught in the grey stays caught and resumes from there (`systems/greyhush`). Props stop below 0.2 ("Stop below 0.2 memory", user, 2026-10-09; `AmbientMath.advance`). Water springs have no threshold (`architecture/memory-gated-height-field`), but the grass follows props, as the user chose.
- Characters (Ivo, guardians) are culled from the root canvas and composited after `Greyhush`, so no world-canvas z can draw over them. Only `ForegroundPass` (bit 4) can (`architecture/foreground-layer`).
- Tiles are 2x (one art pixel = 2x2 game px, `systems/art-pipeline`). Look sheets carry a lip per band on every exposed top: grass blades plus mat, leaf litter, snow (`WangSheet.blade_strip/litter_strip/snow_strip`). Earth (density 0.7, 4 art px spill) and village stone (moss fringe, density 0.25) both have grass lips. `legacy` is pack art with blades baked in.
- A room builds when its contents load. The current room and every touching room run; idle rooms are hidden and DISABLED; evicted rooms are freed (`systems/rooms`).

## Options considered

**Placement**
- Baked at import into `RoomMap`: rejected. It needs a FORMAT bump, and every change to the placement rule or to a biome's grass flag leaves stale imports on every machine (`gotchas/import-plugin-output-is-stale-when-its-logic-changes`). WORLD-07 kept everything but the biome id out of the import for this reason.
- A legend character or a `[grass]` layer: rejected. The user wants grass where the turf is, and authoring it would double the map work.
- **Chosen: derived at build** by `GrassPlacement.runs(map)`. A scan of at most a few hundred cells, once per contents load.

**Drawing**
- MultiMesh blade quads, rotated or sheared: rejected. Rotated thin quads land off the 2x grid with sub-pixel staircases, and every blade's transform must be uploaded every frame.
- CPU `_draw()` of each art pixel: rejected. Thousands of draw commands rebuilt every frame in GDScript.
- Pre-baked bend frames per tuft (`AmbientMotion`-style): rejected. A contact bend is continuous per blade, and the frames multiply by variant and pose.
- **Chosen: one `canvas_item` shader on one quad per run per row.** The fragment shader finds the art pixel (`floor(world_pos / 2)`) and checks the blade roots within `MAX_BLADE_ART` columns of it. The motion lives in a small data texture.

**Motion resolution**
- A spring per art column (2 px): 16 per cell, about 1000 on a busy screen. Too many for GDScript every frame.
- A spring per cell (32 px): coarser than Ivo's body (about 20 px wide), so a contact would bend a block of blades.
- **Chosen: a spring per 4 px segment** (8 per cell). The shader interpolates between segment centres inside a cell, and each blade gets a hashed stiffness. Sway does not go into the springs; the shader computes it from per-cell phases, so a run's springs can sleep when nothing touches it.

**Z order**
- Back row only: rejected as the default. Every blade stands behind Ivo's legs, which reads as a strip behind him rather than him walking through grass.
- Blades in `CreatureMask`: rejected, for the same reasons as `architecture/foreground-layer`: creature shading, the veil, and being reflected through `greyhush_creature_pass`.
- **Chosen: a dense back row in the root canvas and a sparse, short front row in `ForegroundPass`.** Both use the same shader and the same data texture.

**The tile lip**
- Remove it: rejected. The top loses its silhouette wherever blades are hidden (winter, or between sparse tufts).
- Keep it whole: rejected. Static blades would stand under the moving ones.
- **Chosen: a short turf.** Grass looks' spring lip keeps the mat and stubble at most 1 art px tall. Autumn litter and winter snow are unchanged.

**Palette source**
- Colours typed into a `.tres`: rejected, because they drift from the turf.
- **Chosen:** `assemble_tile_sheet.gd` writes the blade palette from the same recipe as the sheet.

## Decision

**Data.**
- `GrassLook` (`@tool` Resource, `resources/world/grass/`; `@tool` because `@tool BiomeTileset.problems()` calls it: `gotchas/a-tool-script-cannot-call-methods-on-a-non-tool-resource`). It holds:
  - `palette: Texture2D`: shades from dark to lit, one row per band (spring / autumn / winter), with winter transparent;
  - `band_of_season` (2, 0, 1, 0);
  - per band `density` (0..1) and `height_min`/`height_max` (art px, at most `MAX_BLADE_ART` = 8);
  - `front_share` (0..1; 0 means no front row) and `front_height` (scale on the blade height);
  - `profile: GrassProfile`;
  - `problems()`.
- Starting values. Village earth: spring 0.7, 3-7 art px; autumn 0.45, 2-5; winter 0. Village stone: spring 0.25, 1-3; autumn 0.15, 1-2. `front_share` 0.25, `front_height` 0.6.
- `GrassProfile` (`@tool`; motion shared across biomes, the way `WaterProfile` sits beside `WaterLook`):
  - `stiffness` 160 /s² and `damping` 10 /s;
  - `push` 0.85 (bend at contact) and `reach` 8 px (falloff past the body's half width);
  - `lean` 0.9 (tip offset at full bend, in blade heights) and `shorten` 0.35;
  - `sway_amplitude` 0.12 and `sway_hz` (0.31, 0.77).

  All are starting values.
- `BiomeTileset` gains `earth_grass`, `stone_grass` and `wood_grass` (`GrassLook`, null means none) and `grass(look)`. `problems()` flags grass on a missing look. `village.tres` gets earth and stone; `legacy` gets none, because its pack lip already has blades.

**Placement** (`GrassPlacement`, pure, static).
- A cell is a grassy top when:
  - its drawn look (`map.looks`, platforms included) has a `GrassLook`;
  - the cell above is air or above the map;
  - the cell above holds no water, reach or shell reach.
- It keys on looks, not `ground`, so anything drawn as ground grows grass.
- Consecutive tops of one look in a row form a `GrassRun`: row, first and last column, look, `open_left` and `open_right`.
- An end is open where the cell beside it is air. There the shader leaves the biome's rounded-corner `radius` free of blades. An end at the map edge is closed, because the resolver continues the ground past it.

**Nodes.**
- `RoomMapNode._build` adds a `Grass` child (`GrassField`) after `Ledges` and before `Solid`, only when there are runs. It is never added in the editor, because a non-tool node script cannot be called there. The editor preview stays ground only.
- `GrassField` (Node2D) owns the runs, one `GrassSprings` per run, the per-cell memory, the phases, and one `GrassTexture` per run. It creates `GrassStrip` children: one back strip per run (z 0, root canvas), plus one front strip when `front_share` > 0 (`CanvasPass.join_layer(strip, CanvasPass.FOREGROUND)`).
- `GrassStrip` (Node2D) draws one rect in `_draw()`, which gives it a cull rect. The rect spans the run plus `MAX_BLADE_ART` art px on each side and above, and 2 px below the walk line. Each strip owns its own copy of the material. `clip_rect` is the room rect, as on the tiles (`bugs/a-rooms-ground-art-hangs-...`).

**Motion and memory** (`GrassField._physics_process`, `GrassSprings`, pure).
- Off screen or hidden, nothing advances, as with props. Each cell's memory is read with `MemoryField.sample` at the centre of the cell's walk line, every 3 physics frames (WaterBody's `RATE_REFRESH_FRAMES`).
- Each cell has two sway phases. Each advances by `AmbientMath.advance` and is stored as `fposmod(time * hz, 1)`, so the GPU never sees a large float.
- Spring per segment: `a = -stiffness * (bend - target) - damping * velocity`, integrated with semi-implicit Euler, with `dt = delta * rate`. `rate` is the cell's memory clamped to 1, and **0 below `AmbientMath.STOP_THRESHOLD` (0.2), where bend and velocity are untouched**. A bent blade stays bent in the grey and resumes from the same state. Sub-steps follow `WaterSurfaceField`'s rule.
- `STOP_THRESHOLD` becomes one const in `AmbientMath`; `AmbientMotion.stop_threshold` defaults to it.
- A run is awake while a body is in its contact band or its springs are not resting. A sleeping run only advances its phases.
- The texture is uploaded only when a phase or a spring changed. A run that is entirely grey uploads nothing.

**Contact** (`GrassContact`, pure).
- The bodies are the visible `CHARACTERS_GROUP` members, gathered once per frame through `body_rect()`. A body counts only while its bottom is within [walk − 16, walk + 4] px.
- Segment target: `sign(x - centre) * push`, at full strength under the body's half width and falling to 0 at `reach` beyond it. At `d == 0` the sign is +1. Of several bodies, the strongest target wins.
- Grass only reads characters, never writes to them. It has no collision and nothing reads it back, so Ivo never freezes; the grass does. In grey grass his push is ignored, because that time is stopped.

**Drawing** (`grass_blades.gdshader`, includes `seasonal_common.gdshaderinc`).
- **Grid.** Art pixel `ap = floor(world_pos / 2)`, so the grid is anchored to the world and aligned with the tiles.
- **Blades.** A blade roots in each art column whose integer hash is below the band's density. Its height and stiffness come from further hashes. Its bend is the segment value (interpolated only inside its cell) plus the sway, times its stiffness, clamped to ±1. Its phase comes from its world column, so a run continues seamlessly across a room seam.
- **Drawing a blade.** The blade is a connected, 8-way line one art pixel wide: row h is offset by `round(bend * lean * H * (h / H)^2)`, the height shrinks to `H * (1 - shorten * bend^2)`, and gaps between rows are filled. Alpha is 0 or 1. Colour comes from `texelFetch(palette, (shade by h / H, band))`, with the tip lit.
- **Rows.** The back row draws blades whose second hash is ≥ `front_share`; the front row draws the rest, scaled by `front_height`.
- **Constraint.** The loop bound is `MAX_BLADE_ART`. The constant in the shader must match the one in `GrassLook`.
- **No GDScript copy.** The shape is rendering-only and no gameplay reads it, the same reason the greyhush edge has none (`gotchas/glsl-gdscript-math-must-be-duplicated`).

**Seasons, grey, water.**
- **Season.** The band is `gh_band_for(gh_season_at(SCREEN_UV) or region season, band_of_season)`, read per game pixel exactly as `seasonal_art.gdshader` reads it, so a blade and the turf under it swap on the same pixels. Winter's density is 0, so no blades are drawn there. `distance` is 0.
- **Grey.** The back row is greyed by the greyhush pass like any world pixel. The front row is greyed by the foreground composite (`clipped_pass` false).
- **Water.** Back strips are at z 0, below water's 50, so the screen copy reflects them and water covers them. The front row is never reflected, the same rule as the foreground.

**Process and residency.**
- `GrassField` keeps `PROCESS_MODE_INHERIT`. It is not under an ALWAYS parent, so `Room.deactivate()`'s DISABLED reaches it, and a visibility early return backs that up (`gotchas/an-explicit-process-mode-escapes-a-disabled-ancestor`).
- It stops under a performance freeze and under a menu hold, like props. Add it to the pause-mode map in `systems/songs-and-the-memorina`.
- Its state lives in the contents. An idle room keeps it. Eviction, a rest's `wake` and a death rebuild reset it to upright, the same limit water ripples have.

**Not added:** no signal (continuous state is pulled, as `ForegroundPiece` and `AmbientMotion` do), no autoload, no `.room` syntax, no importer FORMAT bump, no user-facing string (no `tr()` key needed).

**SOLID.**
- Open/closed: a biome gets grass from a `.tres`, with no code change.
- Single responsibility: placement, contact and springs are three pure classes; `GrassField` is glue; `GrassStrip` only draws.
- Dependency inversion: the field depends on `BiomeTileset.grass()` and `MemoryField.sample`, never on a sheet or a source.

## Consequences and risks

- **Budget.** Under 0.2 ms CPU per frame on the busiest village view: at most about 60 on-screen cells sampled every 3 frames, springs only in awake runs (Ivo touches 1-2), and at most about 10 uploads of 160 RGBAF texels. On the GPU, at most about 80k fragments, each checking at most 17 roots. Measure it in the playtest and record it in `systems/grass`.
- **The pulse feather.** The season dither is per game pixel, so an art pixel can split 1x1 at a pulse edge, the same as the tiles.
- **The front row.** The front row dims Ivo's feet under the lesson dim, and the reflection shows no front blades. Both are minor; `front_share` 0 removes them.
- **Seams.** Cell clocks diverge across a memory edge, but blades are discrete and already out of phase, so there is no continuous feature to shear (unlike `bugs/lake-glints-shear-at-column-seams`).
- **Region seams.** A neighbour room across a region seam samples memory as already accepted (`bugs/a-neighbour-room-in-another-region-...`).
- **Coverage.** Only the `village` biome (12 rooms) gets grass until other biomes have art. WORLD-21's "a gap in the grass" hint will need a suppression mark later. It is not designed here.
- **Height over the lip contract.** Blades rise up to 14 px over the walk line, above the lip contract's 6 px. They have no collision, and the back row stands behind Ivo. Judge it in the playtest.
- **Not included.** Wind (`Airflow`) does not bend the grass in this plan.

## Files

- **Create:**
  - `scenes/world/environment/grass/`: `grass_field.gd`, `grass_strip.gd`, `grass_springs.gd`, `grass_contact.gd`, `grass_placement.gd`, `grass_run.gd`, `grass_texture.gd`, `grass_blades.gdshader`;
  - `resources/world/grass/`: `grass_look.gd`, `grass_profile.gd`, `grass_profile.tres`, `village_earth_grass.tres`, `village_stone_grass.tres`;
  - `assets/sprites/world/tilesets/village/{earth,stone}_blades.png` (generated);
  - `docs/knowledge/systems/grass.md`.
- **Change:**
  - `biome_tileset.gd`, `village.tres`;
  - `room_map_node.gd`, adding `Grass` to the child order;
  - `ambient_math.gd` and `ambient_motion.gd` (`STOP_THRESHOLD`);
  - `wang_sheet.gd`: a `blade_strip` `max_blade`;
  - `assemble_tile_sheet.gd`, which writes `<look>_blades.png` from a lip's `"blades"` colours (spring reuses `greens`; autumn gets a new dry list);
  - `village_earth.json` and `village_stone.json` (`"max_blade": 1`, `"blades"`), then regenerate both sheets;
  - `map_guide.gd`, adding a grass column to the generated tilesets section, then regenerate `docs/maps/README.md`.
- **Docs:** the `CLAUDE.md` systems row, `systems/rooms`, `systems/seasonal-art`, `systems/props`, the pause-mode map, `glossary.md` (grama gerada → `GrassField`, folha → blade), a dated Revision on `architecture/biome-tilesets` (the lip contract for grass looks), and the roadmap.

## Tests

- **`grass_placement_test`:**
  - exposed tops make runs, and a covered top makes none;
  - a top under water, `r` or `u` makes none;
  - `=` ledges grow grass;
  - a look without grass, and `legacy`, make none;
  - open and closed ends, including at the map edge;
  - looks split runs;
  - the map's top row counts;
  - `[back]` changes nothing.
- **`grass_springs_test`:**
  - rest stays at rest;
  - the bend settles on its target;
  - below 0.2, bend and velocity are bit-identical over 600 steps, and the spring then continues exactly as an uninterrupted one from that state;
  - rate 0.5 equals rate 1 at half the delta;
  - `is_resting`;
  - delta 0 does nothing;
  - it stays stable at the largest delta.
- **`grass_contact_test`:**
  - sides push away from the centre;
  - the push falls off to 0 at `reach`;
  - a body above the band, or on another level, does not push;
  - of two bodies, the stronger wins;
  - an empty rect does not push.
- **`grass_field_test`:**
  - a village map builds `Grass` between `Ledges` and `Solid`;
  - back and front strips per run, and front strips carry only bit 4;
  - the material's `clip_rect` is the room rect;
  - at memory 0 the texture bytes are unchanged with Ivo standing in the run, and at memory 1 they change;
  - a hidden field does nothing;
  - no field is built in the editor.
- **Updated suites:** `biome_tileset_test` (grass problems, `GrassLook.problems()` for every `.tres`), `room_map_node_test` (child order), `ambient_math_test` (the const), and `map_guide_test`. The shader scan (`verify-gates`) covers the new shader.
- **Playtest** (village street):
  - walk, stand and roll through the grass;
  - a well of forgetting: walk through without a response, bend the grass, leave, then a pulse resumes it from the bent state;
  - autumn and winter pulses across bent grass;
  - the front row over Ivo's feet;
  - a reflection, where a village top meets water;
  - the frame-time probe.

## Question for the user

1. Should wind (Vendaval, currents) also bend the grass? The recommendation is to leave it out of WORLD-23 and make it its own small item later.
