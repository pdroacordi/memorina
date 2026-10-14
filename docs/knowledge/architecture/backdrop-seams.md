---
id: architecture/backdrop-seams
type: architecture
title: Backdrop seams - every pixel near a room edge is drawn by exactly one room, chosen by a Bayer-jittered point; repeating axes are phased on the world; every room has a backdrop (WORLD-22)
status: active
tags: [backdrop, seam, dither, bayer, rooms, residency, underground, interiors, art-contract, plan, world-22]
related: [systems/backdrops, architecture/vertical-backdrops, systems/rooms, systems/world, systems/greyhush, systems/seasonal-art, systems/art-pipeline, bugs/a-running-neighbour-rooms-backdrop-draws-over-the-current-room, bugs/a-neighbour-room-in-another-region-runs-on-the-current-regions-memory, bugs/the-room-shell-generator-writes-pre-world-07-rooms, bugs/creature-pass-frozen-transform-floats-bodies, gotchas/glsl-gdscript-math-must-be-duplicated, gotchas/rect2-intersects-is-false-for-rects-that-only-share-an-edge]
created: 2026-10-10
updated: 2026-10-13
source_files:
  - scenes/world/environment/backdrop/backdrop.gd
  - scenes/world/environment/backdrop/backdrop_math.gd
  - scenes/world/environment/backdrop/backdrop_layer.gdshader
  - resources/world/backdrops/backdrop_layer.gd
  - scenes/world/rooms/room_residency.gd
  - tools/maps/gen_world_shells.py
---

> **Status: BUILT** (2026-10-10, WORLD-22; design 04 §1 "Emenda entre salas", §6 "Fundos verticais"). Deviations:
> - **Placeholder art.** The new sets have placeholder sheets drawn by `tools/art/draw_backdrop_placeholder.gd`, which reuses `TilePainter` at a 256 art px period, instead of an `ArtPrompt` `placeholder:` key. Each placeholder has a contract under `tools/art/prompts/backdrop_*.md`.
> - **The crater** uses `basalt_caves` until its crossing set.
> - **One band underground and indoors,** as recommended. The user was not asked again; this note records the choice.
> - **The dither is on the 1 game px grid,** like the greyhush edge. The `floor(game_px / 2)` fallback is unused.
> - **Caves are one layer** (no `_near` silhouettes yet), interior sheets are 512 px (256 art px), and the underground sets are `UNDERGROUND_SETS` in the generator, not a `REGIONS` column.
> - **Tests built:** one owner per seam pixel (side by side, a four-room corner, a room against the void), the jitter, band 0, `layer_anchor`, every set's first layer opaque, every contents scene with one `Backdrop`. Not built: the neighbour-count scan and a world-phase engine test (a headless probe checked 512 placements in review).

## Context

- User (2026-10-10): "The transition in kind of the same room when a part of the room is grey and the other isn't is not that good, its just a line, could have more of a gradient or something like that."
- Measured at the square's well (x 640..1280): the square's backdrop is clipped to its rect (`room_rect`, `bugs/a-running-neighbour-rooms-backdrop-draws-over-the-current-room`), so it stops at y 384; `village_cistern` has no `Backdrop`, so below the seam the engine's clear colour shows. `project.godot` sets no `default_clear_color`, so it is Godot's default grey (0.3): the "grey half" is a missing backdrop that reads as the greyhush.
- 27 of 66 contents scenes have no `Backdrop` (list below).
- Same-set neighbours also cut today: the anchor x is each room's origin, so two rooms of one set draw a layer `dx * scroll.x mod strip_w` px apart at their shared edge (square/mill at x 1920: 512 px on the front trees). Derived from `BackdropMath.anchor_position`; not yet seen on screen.

## Options considered

- **Who draws the seam.**
  - (a) **Exclusive ownership by a jittered point (chosen).** See Decision.
  - (b) Overdraw: each room opaque in its rect, plus a dithered spill into neighbours from a second quad per layer at z -29. Needs no neighbour list and cannot hole, but doubles every layer's nodes and draws, and the spill quad of a far layer is near screen-wide (the band sweeps through layer space with the camera).
  - (c) Each room fades out alone toward its edges. Every faded pixel shows the clear colour: the bug, dithered.
  - (d) One backdrop per screen region, picked by the camera. Breaks room anchoring, needs a camera mirror (`bugs/creature-pass-frozen-transform-floats-bodies`) and a timed fade, and still cannot show two sets in one still frame astride a seam.
  - (e) Extend a room's backdrop past its edge. Tree order picks the winner, the surface biome shows underground, and it is the bug the clip fixed.
  - (f) An alpha gradient. Rejected: the project's boundaries are ordered dither (`systems/greyhush`), and `style.md` forbids smooth gradients.
- **Dither grid.** Screen game pixels, `floor(SCREEN_UV * game_size)` (chosen): every room's shader gets the same cell index for a fragment, and it is the greyhush boundary's grid. World pixels would not crawl under a pan, but at zoom 1.5 every third pixel centre lands on an integer world x, so two rooms can floor to different cells and leave a hole.
- **Horizontal phase.** World-phased on a repeating axis (chosen); room anchors (today: a cut at every same-set seam); region anchors (every region sits at (0, 0), so this equals world phase plus a lookup).
- **Neighbour list.** Built by `Backdrop` from `RoomResidency.touching` over `Room.GROUP` (chosen); hand-authored per room (drifts); written by the generator (misses hand-placed rooms and trials).
- **Underground continuity.** Each underground room gets its own set, and the band joins it to the room above (chosen; 04 §6: "Salas subterrâneas usam camadas próprias"). Rejected: the surface set continued into underground rooms at the surface horizon. That fits only rooms that cross the horizon, which keep the cap + tile of `architecture/vertical-backdrops`.

## Decision

- **Ownership.** A pixel at world point `p` is drawn by the room whose rect contains `q = p + j`, where `j` is a per-axis Bayer jitter in `[-N/2, N/2]`. If `q` lies in no room (void, an open top, an interior's edge), `p`'s own room draws it. Rooms tile without overlap, so each pixel has exactly one owner. Ownership depends only on world geometry and the screen cell, never on which room is current, so a seam crossing or a region cut cannot pop the backdrop.
  - `j = (BAYER[cell] + 1/32 - 1/2) * N`: 16 levels, 4 px apart at `N` = 64, symmetric, 50 % at the edge. The y axis reads the transposed cell, so corners do not move along the diagonal.
  - Float safety: the own test uses the rect grown by `SEAM_EPSILON` (0.01 px), the neighbour test uses neighbour rects shrunk by it. Two shaders that disagree by float noise then both draw the pixel (harmless, the stacks are opaque) and never both skip it.
  - `N = 0` is today's `room_rect` clip.
- **`Backdrop.SEAM_BAND`** = 64 px (starting value; playtest 64 against 96). It is the same band at every seam: surface/surface, surface/underground (vertical), different sets or regions. A region seam blends too: the camera cuts there, but a still frame at a room's edge shows the band.
- **World phase.** `BackdropMath.layer_anchor(room_anchor, repeat_x, repeats_y)` returns x 0 when `repeat_x`, y 0 when `fill_above` and `fill_below` are both REPEAT, and the room anchor otherwise. The room's horizon matters only on an axis where the art has an edge. Two rooms of one set with the same world horizon then draw identical pixels, so their band is invisible. Underground (REPEAT/REPEAT) rooms need no horizon convention.
- **`Backdrop.refresh()`**:
  - `neighbours` = the bounds of `RoomResidency.touching(room, get_tree().get_nodes_in_group(Room.GROUP))` without the room itself, at most `MAX_NEIGHBOURS` (8, the shader's array size).
  - `ref` is computed per layer, from that layer's anchor.
  - `cover_rect` margin becomes `MARGIN + SEAM_BAND / 2`. That holds for every camera, the neighbour's included, because for scroll below 1 a pixel past the room's edge moves inward in layer space as the camera moves on.
  - No `Room` (the editor): no neighbours, band 0, no clip, as today.
- **`backdrop_layer.gdshader`.** Includes `dither_common.gdshaderinc` and adds `uniform vec4 neighbour_rects[8]`, `neighbour_count` and `seam_band`. The `room_rect` test becomes `bd_keeps(world_pos, world_pos + bd_jitter(game_px))`, with `game_size = textureSize(greyhush_season_mask, 0)`. The neighbour loop runs only where `q` has left the own rect (inside the band). No `TIME`, no `FRAGCOORD`, no colour: the band only picks whose texels show.
- **`BackdropMath`** (pure, GDScript twins of the shader): `BAYER` (must match `dither_common.gdshaderinc`), `seam_jitter(game_px: Vector2i, band: float) -> Vector2`, `keeps(point, jitter, own: Rect2, neighbours: Array[Rect2]) -> bool`, `layer_anchor(...)`. `BackdropLayer.repeats_y() -> bool`.
- **Every room has a backdrop**, and every set's first layer is opaque everywhere it can draw (no NONE fill, `repeat_x`, alpha 255). Otherwise a band pixel handed to that room is a hole.
- **No signals, no autoload, no process, no new nodes or draws.** The geometry is static and read once at build. No user-facing strings.

## Rooms without a backdrop today, and their sets

| Set (new unless noted) | Rooms |
|---|---|
| `village_strata` | village_cistern (WORLD-20 moves it to the caldera as `caldera_cistern`; the set goes with it) |
| `earth_caves` | woods_root_caves |
| `ice_caves` | lake_well, lake_ice_caves, lake_frost_arena |
| `basalt_caves` | caldera_chimney_base, caldera_long_corridor, caldera_bait, caldera_dry_moat, caldera_seesaw, caldera_cistern_bottom, caldera_temple_gate, caldera_arena |
| `caldera_crater` (crossing: sky, rim cap, basalt tile below) | caldera_open_crater |
| `interior_timber` | village_house, village_tavern, village_elder, village_bakery, village_empty_house, threshold_farmhouse, woods_hut, lake_fisher_hut, orchard_inn, door_trial_inside |
| `interior_stone` | village_tavern_cellar, lighthouse_interior (and village_bell_tower once WORLD-20 makes it an interior) |
| `pine_woods` (existing) | door_trial (`horizon_y` 53 px above its floor, like the other trials) |

Data fixes: `orchard_cliff_chimney` `horizon_y` 3307 → 235, the orchard surface. It then shows sky above, joins `orchard_arena` without a band (same set, same world horizon), and below it continues the earth fill into the band with `caldera_chimney_base`. `village_bell_tower` has no `horizon_y` (0, its top); it is moot after WORLD-20.

Starting layers: caves are a far wall (scroll 0.5, `distance` 0.4, opaque) plus a near silhouette layer (0.8, 0.1); strata is one layer (0.6, 0.3); interiors are one wall at scroll (1, 1), `distance` 0. All REPEAT/REPEAT, so all world-phased.

## Art contracts (`tools/art/prompts/backdrop_<set>_<layer>.md`, `command: generate`, `source: codex`)

The shapes in `architecture/vertical-backdrops` "Art contract" apply, plus:
- **2x** ("One 2x pixel density", user, 2026-10-10): one art pixel is 2x2 game px. A 512 px sheet is drawn at 256 art px and doubled with nearest filtering.
- Minimal and outline-free (`style.md`), with the biome palette from its style board.
- One band, so seasons do not reach underground (open question 1).
- The far wall is one value step darker than the biome's ground body, so the playable ground reads in front of it. Low frequency, no speckle.

| Contract | Size (game px) | Notes |
|---|---|---|
| `backdrop_village_strata_far` | 512x512 | soil and rock in horizontal bands; opaque; seamless both axes |
| `backdrop_earth_caves_far` / `_near` | 512x512 each | earth wall, opaque / hanging roots and earth pillars, transparent, nothing cut at a wrap |
| `backdrop_ice_caves_far` / `_near` | 512x512 each | blue ice wall / hanging ice |
| `backdrop_basalt_caves_far` / `_near` | 512x512 each | columnar basalt wall / column silhouettes |
| `backdrop_caldera_crater_sky` | 1024x384 | top and bottom rows flat (EDGE both) |
| `backdrop_caldera_crater_rim` | 1024x384 | ragged transparent top; its bottom rows run into `basalt_caves_far`, which tiles below it (NONE/REPEAT, same scroll) |
| `backdrop_interior_timber` / `_stone` | 256x256 each | plaster and beams / dressed stone; opaque; seamless both axes |

Sequence: interiors and village strata can use the village concept's palette now. The three cave sets wait for their biome boards (WORLD-14/15/17). Until then each set holds a placeholder sheet. `ArtPrompt` gains `placeholder: #rrggbb`, so `make_placeholders.gd` fills an unfinished backdrop with a dark neutral instead of purple. Generating them needs the "Art tooling" from `architecture/vertical-backdrops`: `process_image.gd --tile` with an art scale (fit by one factor, crop, quantize, double), plus a wrap preview.

## Files

- **Change:**
  - `backdrop.gd`, `backdrop_math.gd`, `backdrop_layer.gdshader`, `backdrop_layer.gd`.
  - The 27 contents scenes above, plus `orchard_cliff_chimney_contents.tscn`.
  - `gen_world_shells.py`: `contents()` writes a `Backdrop`. Surface rooms get `pine_woods` at the floor horizon. Underground rooms get their region's set (a new column in `REGIONS`). Interiors get `interior_timber`. Without this, every new shell fails the scan test (`bugs/the-room-shell-generator-writes-pre-world-07-rooms`).
  - `art_prompt.gd` and `make_placeholders.gd` (`placeholder`).
  - Docs: `systems/backdrops` (new never-break text, below), its `CLAUDE.md` row, `systems/world` (the generator), `architecture/vertical-backdrops` (Revision, appended), roadmap WORLD-22.
- **Create:**
  - The 7 sets in `resources/world/backdrops/`, the 11 contracts, and the placeholder sheets under `assets/sprites/world/background/<set>/`.
  - Credits in `CREDITS.md` when the art lands.
- **New never-break:** "A layer is placed only by `BackdropMath`: room horizon on an axis with an edge, world 0 on a repeating axis. A backdrop pixel is drawn by exactly one room, the one holding the pixel moved by the seam jitter. `keeps`/`seam_jitter`/`BAYER` and `art_row`/`art_col` are one mapping in GDScript and the shader. Every room has a backdrop whose first layer is opaque."

## Tests

- `backdrop_math_test`:
  - Exactly one owner for every point within the band, for all 16x16 cell pairs, across these layouts: side by side, stacked, a 2x2 corner, an L with void, a wide room under a narrow one, and a room against the void (keeps its whole rect).
  - Jitter is symmetric, has 16 levels and stays within `N/2`.
  - Band 0 equals the rect clip.
  - `layer_anchor` per fill.
  - Two rooms of one set at x 0 and 1920 with one world horizon give equal `anchor_position` for any camera.
  - The cover with the band margin holds a neighbour camera's view of the band.
  - `test_moving_the_room_moves_nothing_on_screen` is rewritten for horizon-anchored axes only.
- `backdrop_test`:
  - Two touching `Room`s: the material carries the other's bounds and count. An interior alone carries none.
  - `test_a_room_far_from_the_origin_looks_the_same` becomes: every layer is on screen and the vertical pose is unchanged, with a `repeat_x = false` layer keeping the old exact check.
- `backdrop_set_test`:
  - Every set's first layer is opaque and covers every row and column.
  - Every `*_contents.tscn` has exactly one `Backdrop` with a set. This replaces the Parallax2D scan and keeps it.
  - No room touches more than `MAX_NEIGHBOURS` rooms (instances every region scene).
- Playtest (`godot-playtester`):
  - The square's well astride y 384, with a peek down: no flat grey, and a band in the shaft.
  - Square to mill: no cut at x 1920.
  - The cut from gate_east to threshold_fields, plus its resting edges.
  - The drop from woods_deep into the root caves; waterfall path to the ice caves.
  - The top and bottom of the chimney.
  - `village_house`.
  - Zoom 1.5 at a seam, and a pulse across the band.
  - Pixel diffs on the crossing frame against the pan.

## Consequences and risks

- **Every room's horizontal phase changes once** (trials too). WORLD-04's guarantee holds, because repeating quads cover any x. The editor preview shows the reference pose and may differ in phase from the game.
- **Glide residency.** `settle` hides rooms that no longer touch the current room at the swap. A one-screen room left sideways shows, at the frame's far edge, band pixels owned by a room just hidden: holes up to 50 % over 32 px. They last about one frame, because the cubic ease-out glide passes 32 px in its first frame. Playtest it. If it shows, delay the hide by one glide.
- **Across a region seam** the neighbour's band takes the current region's season and haze. This is the accepted residency behaviour (`bugs/a-neighbour-room-in-another-region-runs-on-the-current-regions-memory`).
- **The screen-space dither crawls during a pan**, like the greyhush edge. With 2x art a 1 px dither may read as mixed density; the fallback is `floor(game_px / 2)` cells, which is one constant.
- **Same set, different horizons** (canopy over deep, cliffs beside the lighthouse base) blend two poses of one art over 64 px. Align the horizons if it ghosts.
- **Cost:** two Bayer reads and one rect test per backdrop fragment, a loop of up to 8 only inside the band, and 5 materials x 8 `vec4` per room.
- **Float range:** interiors at x up to about 72000 and scroll 1 give `layer_pos` about 72000 (float step 0.008 px), which is safe for `floor` at pixel centres.

## Open question for the user

1. **Seasons underground.** 04 §6 gives nature art three versions. Recommended: caves and strata are one band (a pulse underground swaps nothing), which also cuts the cave art by two thirds. The alternative: three bands for `earth_caves` (roots bare in winter) only.

## Revision (2026-10-13, BUILT in WORLD-28)

The user, 2026-10-13: "There is no sense in trees there. Nor in the fade between two backgrounds." Choice: "One horizon + hidden cuts (Recommended)": "Each region gets one horizon height, so stacked rooms stop showing the trees twice (12 seams fixed by data alone). Where two different backgrounds meet (9 seams), make a hard cut hidden behind something solid (a gatehouse, a cave mouth, a well rim, a wall) and drop the dither." The 2026-10-10 band answered a seam between a room with a backdrop and one without; between two drawn sets the 1 px Bayer checker read as a muddy cross-fade of unrelated paintings (audit: 21 of 49 world seams showed it).

- **The dither is gone.** `BAYER`, `bayer_index`, `seam_jitter`, `SEAM_BAND`, the `seam_band` uniform and the dither include left `BackdropMath` and `backdrop_layer.gdshader` together. `keeps(point, own, neighbours, ring)` and `void_owner(point, rooms)` test the pixel centre itself: a pixel in a room is that room's; the ring rule is unchanged (160 px, the seam continued straight, the nearest room only at corners). The cover margin is `MARGIN` alone.
- **Same picture, no seam.** Rooms of one region share its set and its one horizon (`architecture/vertical-backdrops`, revision 2026-10-13), and a repeating axis is phased on world 0, so they draw identical pixels and the cut between them is invisible. `BackdropMath.same_picture` says so: one set, equal anchors on every axis where a layer has an edge.
- **Different pictures, hidden cut.** `BackdropSeams.cuts` (pure, `BackdropSeamRoom` in, `BackdropCut` out) walks the 32 px cells of the rooms' rings, gives each its owner by `keeps`, and reports every run of cell edges between two pictures with no opaque cell (ground, void `_`, a `[back]` wall, a lake `w`) on either side. A cell outside every room is never opaque, so a cut continued into the sky is reported too, as a `ring` cut. `backdrop_seams_test` runs it over every room `game.tscn` and `DebugTrials` place (the trials on their own half-cell lattice) and fails on a cut not in `ALLOWED` and on a stale entry. Dividers are `.room` data only (`[back]` walls); 14 of the 15 open cuts in rooms were closed that way; the fishing village's well mouth is allowed until WORLD-29 turns it into a door.
- **Accepted.** `ring` cuts in the void outside both rooms: diagonals at corners (the ring's corner rule), rings that meet at their outer edges, and two seams continued past solid east walls. None lies in a resting frame; a keep-in-view yield past a seam can show a sliver of a corner diagonal. The user accepted a straight line high in the sky above region-border gatehouses until the region backdrops share one sky colour ("OK until skies match (Recommended)").
- **The ring holds before gaps** (same day, after review: `bugs/a-ring-corner-diagonal-shows-a-rock-wall-in-the-mills-sky-on-a-jump`). Without the dither the nearest-gap rule's L-corner diagonal showed as a rock wedge in the mill's sky on a jump. `void_owner` and the shader now rank how a room within `ring` holds the pixel (over its top, beside it, under its floor, past a corner) before comparing gaps, so every boundary is a room edge continued or a ring limit. A rank can hand a pixel of the left room's ring to that room's neighbour, so the left room's neighbours keep running through a glide (the "delay the hide by one glide" fallback above). `ALLOWED` is keyed by segment.
- **Over its top, the region's sky** (same day, second review: `bugs/a-wall-climb-over-the-seam-pillar-shows-the-wall-up-cut-in-the-sky`, `bugs/a-stale-glide-timer-idles-the-left-rooms-neighbours-mid-glide`). A wall climb showed the rock override's edge in the sky over two wall tops. A room that overrides its region's set now draws the region's set over its top (`Backdrop.Part`, `BackdropMath.over_top`), so sky meets sky there; only a region border keeps a line in the sky (`REGION_SKY`, the user's sky-line acceptance). Glide residency settles on `GameCamera.glide_finished`, not a timer.
- **Superseded above:** the Decision's jittered owner, "Across a region seam the neighbour's band", "The screen-space dither crawls during a pan" and "Same set, different horizons ... blend two poses" (one horizon per region removed the 12 horizon seams).
- **One sky over every border** (WORLD-33, 2026-10-13). The sky layer of every surface set has a vertical scroll of 0: a far layer's offset between two horizons is the horizon gap times its scroll, so only scroll 0 makes two regions' skies the same pixels whatever their horizons. Moving the lake and the orchards onto one horizon was rejected: the horizon belongs to the region's height (`Region.horizon_y`), and only the sky has to match. Layers that still differ over the tops are covered by a prop on them (the gate towers, the lake border cairn), checked through `BackdropMath` by `backdrop_seams_test`. `REGION_SKY` is gone.
