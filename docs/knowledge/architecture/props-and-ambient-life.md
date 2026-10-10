---
id: architecture/props-and-ambient-life
type: architecture
title: Props and ambient life - hand-placed Sprite2D prop scenes behind the play plane, one AmbientMotion component that cycles frames on the memory clock of its own point (pure AmbientMath), rotations baked to frames, lit windows greyed like the world, villagers and animals as props, and a RegionPresence rule read from the region's baseline (WORLD-08, WORLD-10)
status: active
tags: [props, set-dressing, ambient, memory-clock, greyhush, stopped-time, villagers, animals, inhabitants, windows, windmill, smoke, seasonal-art, z-order, art-contract, pixellab, codex, plan, world-08, world-10]
related: [systems/greyhush, systems/seasonal-art, systems/backdrops, systems/foreground, systems/songs-and-the-memorina, systems/rooms, systems/art-pipeline, architecture/biome-tilesets, architecture/foreground-layer, architecture/vertical-backdrops, architecture/doors-and-interiors, architecture/memory-gated-height-field, architecture/memory-runs-through-pause, architecture/the-region-owns-its-forgetting, features/regional-weather, gotchas/time-scale-zero-stops-delta-particles-and-time, gotchas/animationtree-reset-track-overwrites-script-writes, gotchas/off-centre-sprite-sheet-jumps-on-flip]
created: 2026-10-09
updated: 2026-10-09
source_files:
  - scenes/world/environment/props/ambient_motion.gd
  - scenes/world/environment/props/ambient_math.gd
  - scenes/world/environment/props/region_presence.gd
  - scenes/world/environment/props/
  - scenes/world/environment/inhabitants/
  - scenes/world/environment/backdrop/backdrop.gd
  - scenes/world/memory/memory_clock.gd
  - tools/art/art_prompt.gd
  - tools/art/process_image.gd
  - tools/art/bake_rotation.gd
  - tools/pixellab/pixellab.ps1
---

> **Status: BUILT (core)**, 2026-10-09 - see "Status (2026-10-09)" at the end.

## Summary

A prop is a `Sprite2D` scene (one PNG per prop: frames side by side, season bands stacked) instanced
by hand under a `Props` node in a room's contents scene, drawn at z -10: in front of the `Backdrop`
(moved to z -30) and of WORLD-07's `[back]` walls (z -20), behind the ground, the entities and the
water. A prop never collides; a surface Ivo stands on is always a `.room` cell. Motion is one
component, `AmbientMotion` (a child Node), that advances a local time by `delta * memory` sampled
at its own point and writes the parent's `frame` from pure `AmbientMath`, so a prop in the grey
holds its frame and resumes from it. Windmills and the water wheel are rotation frames baked
offline, not runtime rotation. Lit windows are separate frame-cycled sprites in the world canvas,
greyed and stopped like everything else. Villagers and animals are props (not `Character`s): idle
loops from PixelLab, a fixed facing (`flip_h`), no collision, never in a `CanvasPass`. A
`RegionPresence` child hides its parent while the region's baseline is below `min_baseline`,
which is how the village loses people at 0.6.

## Context

- Design 04 §5 ("Idle villagers, no dialogue", user, 2026-10-08): villagers at their work with a
  short idle loop (PixelLab), animals, signs of life (chimney smoke, laundry, lit windows, flags,
  windmills). Everything freezes in the grey: each runs on the memory clock of the point where it
  stands; a villager in a forgotten area stops mid-gesture and resumes when a pulse passes. The
  village loses people when its memory falls to 0.6; all are back at the Return.
- Design 04 §6: the world is 1x; nature art has three versions (spring, autumn, winter), built
  things one. "All doors": every building has a door and an interior.
- Design 03 §2 and `systems/greyhush`: grey is stopped time, not lower amplitude. Characters never
  freeze; environment does. No shader reads `TIME`.
- Already built: `Backdrop` (first child of `Contents`, z 0 today), `ForegroundPiece` (own pass,
  bit 4, ALWAYS), `MemoryClock` (drives a target's `speed_scale` from `MemoryField.sample` at its
  first Node2D ancestor, stop threshold 0.05, PAUSABLE), `RegionWeather`, the seasonal material.
  Planned: WORLD-07's `[back]` walls (`architecture/biome-tilesets`).
- Rooms are text, but a prop carries no gameplay, is free-positioned and is not on the 32 px grid,
  like a foreground piece or a backdrop. The `.room` rule covers ground and entities, not art.

## Options considered

**Draw depth.**
- Props by tree order only (`Backdrop`, `Props`, `RoomMap`, all at z 0): rejected. `[back]` walls
  are built under `RoomMap`, so a barrel in a cellar would draw behind the cellar's wall.
- Props in front of the ground (z > 0): rejected. A barrel's foot would cover the ground's
  seasonal lip, and a facade would draw over steps and ledges.
- **Chosen:** z bands. `Backdrop` -30, `[back]` walls -20, `Props` -10, ground and entities 0,
  water 50 (`WaterQuad.Z`). The ground's top lip overlaps a prop's foot, so snow lies over it.

**Motion on the memory clock.**
- `AnimatedSprite2D` or `AnimationPlayer` driven by the existing `MemoryClock` through
  `speed_scale`: deterministic enough, but two nodes and a `SpriteFrames`/`Animation` resource per
  prop, every copy of a prop starts in lockstep (frame 0), the sample point is fixed at the
  sprite's origin (a chimney's smoke and a house's foot are different places), an `AnimationPlayer`
  brings the RESET-track trap, and nothing is testable as math. `AnimationPlayer` alone runs on
  scaled time, so it keeps moving in the grey: what design 03 §2 forbids.
- A shader picking the frame from a per-instance clock uniform: a script still has to sample
  memory, and the frame choice would be duplicated inside a shader that already owns the season
  bands. Rejected.
- One director per room ticking every prop: one loop and one view rect, but every prop is coupled
  to a manager. Rejected for now; revisit only if the cost probe below fails.
- **Chosen:** `AmbientMotion`, one Node per animated prop, PAUSABLE, writing the parent
  `Sprite2D.frame` from `AmbientMath`.

**Rotation (windmill sails, water wheel).**
- Runtime `rotation`: the project stretches with `canvas_items`, so a rotated 1x texture is drawn
  on the window's grid (rotated texels, off the game-pixel grid), against 04 §6's 1x density.
- A rotating shader that snaps to game pixels: correct, but it must merge with the seasonal shader
  and adds a third material path. Rejected.
- **Chosen:** bake the turn offline into frames over one symmetry period (`tools/art/bake_rotation.gd`)
  and play them with the same `AmbientMotion`. Stepped motion, every pixel on the grid.

**Lit windows.**
- Baked lit into the facade: no flicker, and a house cannot go dark when its people leave.
- Additive glow, a `PointLight2D`, or an exception to the greyhush: rejected. Only characters
  escape the grey; a light is the place's life and stops with the place. Soft halos are also
  gradients, which `style.md` forbids.
- **Chosen:** facades draw dark panes; a small lit-pane sprite per window (3 frames of flame
  flicker) sits on top, in the world canvas, with `AmbientMotion` and optionally `RegionPresence`.

**Villagers and animals.**
- `Character` subclasses: physics bodies, gravity, health, the creature pass. A `Character` never
  freezes (`MemoryClock` asserts it), the opposite of what 04 §5 asks. Rejected.
- **Chosen:** props with an idle cycle. Their scenes live under `scenes/world/environment/inhabitants/`,
  not `scenes/characters/`, so nobody adds character behaviour to them.

**The 0.6 population rule.**
- A list of names in a village script, or a `SaveFact` ("two guardians restored"): rejected.
  The first is a hard-coded branch; the second ties people to a guardian count where the design
  ties them to memory.
- Sampling `MemoryField` at the villager: rejected. A pulse or a death mark would make people
  appear and vanish.
- **Chosen:** `RegionPresence.min_baseline` per instance, read from `Region.current_baseline()` and
  `Region.memory_changed`.

**Sheets.**
- Atlases per biome: fewer textures, but the contract system is one target per entry
  (`art_prompt_test`), and re-generating one prop would repack the atlas.
- **Chosen:** one PNG per prop. Frames left to right, bands top to bottom (spring, autumn, winter,
  as `systems/seasonal-art`). About 100 sprites per room is about 100 draw items; repeated props
  share a texture.

## Decision

### 1. Placement and layering

- Every contents scene with props gets a plain `Props` Node2D with `z_index = -10`, after
  `Backdrop` and before `RoomMap`; props are its children, nearest last. A `Foreground` node stays
  where it is (`systems/foreground`).
- `Backdrop` draws at `Backdrop.Z = -30` (set in `backdrop.gd`, asserted like `WaterQuad.Z`).
  WORLD-07 must build `[back]` layers at `RoomMapNode.BACK_Z = -20`; record it as a Revision of
  `architecture/biome-tilesets` when WORLD-07 adopts it.
- Authors instance prop scenes by hand in the editor, snapped to whole pixels. A prop's origin is
  its foot (bottom centre) unless its contract says otherwise; a facade's origin is its doorway's
  sill centre, so it is placed at the door entity's position (the `E` cell's bottom centre).
- **A prop never collides and never carries gameplay.** A roof Ivo walks on, a counter he stands
  on and the well's rim are `.room` cells, and the art is drawn to match them. Where a prop draws
  the surface, the cell must draw nothing: WORLD-07's legend adds two collision-only characters
  (proposal: `_` one-way, `+` solid, both `Enums.Ground.WOOD`, no look).
- Never a prop that looks like an interactable: no loose doors, benches, gates or plates. Only an
  `R`, `E`, `X` or `P` may look like one.
- Water: props are below z 50, so pools reflect them and an opaque lake covers what stands behind
  it (the mill wheel's foot).

### 2. A prop scene

- Root `Sprite2D`, `centered = false`, `offset = -anchor`, `hframes = frames`,
  `vframes = bands`, `frame` in row 0 (band 0).
- Seasonal (3 bands): `prop_seasonal_material.tres`, `seasonal_art.gdshader` with
  `band_count = 3`, `band_of_season = (2, 0, 1, 0)`, `distance = 0`. Built (1 band): no material.
  The shader's `fract(UV.y * bands)` keeps a frame of row 0 inside its band, so hframes and bands
  compose with no code.
- Optional children: `AmbientMotion`, `RegionPresence`. A facade composes its window lights and
  chimney smoke as instanced child props, one level deep.
- `visibility_layer` stays 1 (the root canvas). A prop never calls `CanvasPass.join_layer`.

### 3. AmbientMotion and AmbientMath

`AmbientMath` (RefCounted, static, pure):

```gdscript
static func advance(time: float, delta: float, memory: float, stop_threshold: float) -> float
static func frame_at(time: float, frames_per_second: float, frame_count: int, phase: float, sequence: PackedInt32Array) -> int
static func phase_for(point: Vector2) -> float  # integer hash of the rounded point, 0..1
```

- `advance` returns `time + delta * rate`, `rate = clamp(memory, 0, 1)`, 0 below `stop_threshold`.
- `frame_at`: `L` = sequence size, or `frame_count` if empty; `step = posmod(floor(time * fps + phase * L), L)`;
  the frame is `sequence[step]` or `step`. A sequence gives holds and ping-pong without repeating
  frames in the PNG.
- `phase_for` is an explicit integer hash, not the engine's `hash()`, so a prop has the same
  phase on every load and two chickens side by side do not peck together.

`AmbientMotion` (Node, child of a `Sprite2D`):
- Exports: `frames_per_second` (frames/s at memory 1), `sequence`, `phase` (0..1; negative derives
  it from the position), `sample_offset` (local px where memory is read: a flag's cloth, not its
  pole), `stop_threshold` (default 0.05, `MemoryClock`'s; see question 1).
- `_ready`: asserts a `Sprite2D` parent and no `Character` ancestor (as `MemoryClock` does); sets
  `process_mode = PAUSABLE` explicitly, because a parent `ForegroundPiece` is ALWAYS and a foreground
  laundry line must still stop under a performance; finds the field (`MemoryField.find_in`); none
  means memory 1 (a contents scene opened alone).
- `_physics_process(delta)`: returns if the parent is not visible in the tree or its rect is off
  the view (`get_canvas_transform().affine_inverse() * get_visible_rect()`); otherwise samples the
  field at `parent.to_global(sample_offset)`, advances, and writes `frame` only when it changes.
- Time is not saved. Contents rebuilt by eviction or death restart from 0 with the same phase;
  a deactivated room's props hold (its contents are hidden, and `AmbientMotion` returns while its sprite is not visible in the tree: its explicit PAUSABLE escapes the room's DISABLED) and resume.

Why not `AnimationPlayer`: it advances by the scaled delta, the same in a forgotten place and a
remembered one; a stopped world needs a clock that advances by `delta * memory` at a point.
`MemoryClock` bridges that through `speed_scale` and stays the pattern for `CPUParticles2D` (dust
motes). `AmbientMotion` reuses its rules (sample, threshold, PAUSABLE, no characters) and owns the
frame itself.

Freeze and hold: PAUSABLE, so props stop under a performance (the world's time is frozen while
memory moves) and under a menu hold. **The pause-mode map gains nothing.** A recall's slow motion
slows them through the scaled delta.

Cost: a still prop has no script. Each `AmbientMotion` costs one visibility test, one rect test
and, on screen, one `MemoryField.sample` (one influence per source, at most `MAX_SOURCES` 32) per
physics frame. Off screen nothing advances, which nobody can see. Budget: 60 animated props with
32 sources under 0.5 ms per physics frame, measured by a probe before WORLD-11; above it, the
per-room director.

### 4. Rotation baked to frames

`tools/art/bake_rotation.gd` (a `-s` tool, pure core `RotationBake` with a test) takes a 1x still
of the sails or wheel, its pivot and its symmetry order `k` (4 sails: 90°; 8 spokes: 45°), and
writes `F` frames over one period: upscale x4 nearest, rotate by nearest sampling, shrink x4
keeping each block's most common colour (`ImageOps`' shrink rule), so every colour stays in the
palette. Speed is data: `frames_per_second = turns_per_second * k * F`. The pivot is the frame
centre, so the frame is square. The tower or mill body is a separate still prop.

### 5. Lit windows

- A facade contract lists its window rects; panes are drawn dark and unlit.
- `window_light_<size>` props (3 frames, 1 band, about 3 fps) sit on the panes as children of the
  facade scene. In the grey they grey to a pale pane and hold their frame; a pulse relights the
  flicker. A house emptied at 0.6 goes dark with a `RegionPresence` on its lights.
- Lanterns, hearths, ovens and candles follow the same rule: the flame is frames, the light is
  painted pixels, nothing is additive.

### 6. Villagers and animals

- Inhabitant scenes are prop scenes (`scenes/world/environment/inhabitants/<id>.tscn`): `Sprite2D`
  + `AmbientMotion` (+ `RegionPresence`). No physics body, no hurtbox, not in the `characters`
  group: attacks pass through, `ForegroundPiece` never fades for them, and they draw in the root
  canvas, behind Ivo's creature pass, greyed and stopped by the greyhush.
- Authored facing west, body centred in the frame; facing is `flip_h` on the instance and never
  changes. No dialogue and no reaction to Ivo (dialogue is a STORY item).
- A seated villager is drawn seated; the chair is a separate prop behind it.

### 7. RegionPresence

- Node, child of a prop. Export `min_baseline` (0..1): the parent is shown while
  `Region.current_baseline() >= min_baseline`. 0 is always shown.
- `_ready`: finds the region (`Room.of(self).get_region()`; no room means shown), applies the
  baseline, connects `Region.memory_changed(level)` to `apply(level)`. The decision is pure:
  `static func shown(level: float, min_baseline: float) -> bool`.
- Village data (WORLD-11): the people who leave at 0.6 get `min_baseline = 0.7`; everyone else 0.
  The village is 0.8 at the start and 1.0 at the Return, so nobody needs an upper bound. The drop
  to 0.6 itself is MEM-13.
- A hidden parent also stops its `AmbientMotion` (it tests visibility first).
- The change applies when the signal arrives. The drop happens while Ivo is in another region; the
  Return is staged by its STORY item, which should change the baseline behind a fade.

### 8. Signals

No new signals. `RegionPresence` consumes `Region.memory_changed` (already emitted, one direction:
the region never learns props exist). `AmbientMotion` pulls `MemoryField.sample`.

## Tests (gdUnit4, `--ignoreHeadlessMode`)

- `tests/scenes/world/environment/props/ambient_math_test.gd`: memory 0 leaves time unchanged over
  10,000 steps; memory 1 sums the deltas; below the threshold is 0; memory above 1 is clamped;
  resume: 1.3 s at 1, 5 s at 0, then 0.7 s at 1 shows the frame of 2.0 s at 1; wrap at `L`;
  sequence lookup; phase shifts the step; `phase_for` is stable, in 0..1 and differs between
  neighbours one cell apart.
- `ambient_motion_test.gd`: a `Sprite2D` + `AmbientMotion` and a `MemoryField` with baseline 0 holds
  its frame; at 1 it advances at `fps`; a hidden parent does not advance.
- `region_presence_test.gd`: `shown()` at, above and below the threshold; `apply()` toggles the parent.
- `prop_scenes_test.gd` over `scenes/world/environment/props/**` and `inhabitants/`: root is a
  `Sprite2D`; no `CollisionObject2D` anywhere; `visibility_layer == 1`; `vframes` equals the bands of
  the art contract whose target is the texture, `hframes` its frames, `offset == -anchor`; a seasonal
  material only on 3-band sheets; every `sequence` entry is below `hframes`.
- `contents_layering_test.gd` over every `*_contents.tscn`: `Backdrop` is first and at `Backdrop.Z`;
  a `Props` node is at z -10, before `RoomMap`.
- `rotation_bake_test.gd`: frame 0 equals the source; one period later is frame 0 again; every output
  colour is in the source.
- `art_prompt_test`: the new contract keys (below).
- Smoke: the dressed demo room is a trial room, already in `tools/smoke/scenes.txt`.
- A playtest after WORLD-08 in `trials_solstice/door_trial` (x 18560, memory 0.35): a facade with a
  window light, smoke and a sign, a villager and a chicken, a windmill. Check: everything runs at
  0.35, a pulse makes the ones inside it run at full speed, they hold their frame when it fades;
  Ivo draws in front of the villager; frames under a performance and under a menu are identical.

## Files

- New: `scenes/world/environment/props/{ambient_motion,ambient_math,region_presence}.gd`,
  `prop_seasonal_material.tres`, `props/<biome>/<id>.tscn`; `scenes/world/environment/inhabitants/<id>.tscn`;
  `tools/art/bake_rotation.gd` (+ `RotationBake`); the tests above.
- Changed: `backdrop.gd` (`Z`) and `systems/backdrops`; `art_prompt.gd`, `make_placeholders.gd`,
  `process_image.gd` (`bands`, `palette`, `anchor`, `--band=`); `pixellab.ps1` (v2 `character`,
  `animate-character`, `object`, `object-animation` commands; key handling unchanged); `CREDITS.md`.
- Docs: a new `systems/props` entry and its `CLAUDE.md` row (never break: a prop never collides and
  never joins a `CanvasPass`; ambient motion runs only on the memory clock, through `AmbientMotion`);
  the glossary (adereço → prop, aldeão → villager/inhabitant, sinais de vida → ambient motion).

## Art contract (props and inhabitants)

> **Revision (2026-10-10, WORLD-10).** Inhabitants were made differently from the plan below: stills cut from one Codex sheet of the village's people (our concept and fronts as references), then PixelLab `animate-with-text-v3` from each still (8 frames, played ping-pong at 6 fps), not `create-character-v3` plus `animate-character`. Contracts use `command: animate3`. Frames: adults 64 px, children 48, animals 32 (the cat 32x32, not 32x16; hens 32). `prop_scenes_test` is built (Sprite2D root, no collision, visibility layer 1, sequence frames inside `hframes`); the band and contract checks it planned are left to `art_prompt_test`.

- Contract keys added: `bands: 1|3` (sheet = `size.x * frames` by `size.y * bands`), `palette: <biome>`
  (`tools/art/palettes/<biome>.json`, `style.md`), `anchor: x,y` (origin in the frame; default
  bottom centre). The autumn and winter bands are edits of the processed spring band at 1x (Codex
  image edit or PixelLab `edit-images-v2`), never fresh generations, so the silhouette holds;
  `process_image.gd --band=<i>` writes one band of the target.
- 1x, binary alpha, the `style.md` outline and shading, no letters anywhere (signs are pictograms),
  low-frequency shapes. Read in silhouette and value: a forgotten prop keeps only those.
- Paths: `assets/sprites/world/props/<biome>/<id>.png` (biomes as WORLD-07: `village`, `interior`, ...);
  `assets/sprites/world/inhabitants/<id>.png`.
- Sources: stills from Codex (default). Inhabitants from PixelLab: `create-character-v3` (side view,
  west, the approved concept as style reference, which is our art) then `animate-character` (even
  frame count 4..16), west frames only. Flags, laundry, signs and flames: a Codex still animated by
  PixelLab (`animate-with-text-v3`, or `create-1-direction-object` + `objects/{id}/animations`).
  Chimney smoke: procedural (`draw_procedural_sprites.gd`), so the loop is seamless. Windmill and
  wheel: Codex still + `bake_rotation.gd`. Review every loop at its seam (last frame to first).
- Sizes: villager frames 64x64 (adult body 48 to 54 px; Ivo's capsule is 54), children 48x48,
  8 idle frames at 6 fps. A facade's width is its greybox roof run and its eave or ridge sits on its
  `.room` ledge row; the doorway is a dark 32x64 recess the door sprite fills.

## Village props (for WORLD-11)

> **Revision (2026-10-10, WORLD-11).** The street is flat (WORLD-20), so a facade is sized by its doorway (64 px), not a roof run on a ledge row, and drawn at 2x. Built sizes: `ivo_house_facade` 238x218, `bell_tower_facade` 100x266 (new: the tower is a door interior), `tavern_facade` 356x246 at door col 38 (moved from 36 to clear the well), `elder_house_facade` 246x220, `bakery_facade` 220x166, `empty_house_facade` 232x190; `systems/props` (Facades) is the contract. The table below keeps the planned 1x sizes for the props not yet built.

Size is one frame at 1x. F frames, B bands. Every one is a contract in `tools/art/prompts/`.

| id | what | size | F | B | source |
|---|---|---|---|---|---|
| `ivo_house_facade` | square, door col 8, roof run cols 3-12 (row 5) | 320x192 | 1 | 1 | Codex |
| `tavern_facade` | square, door col 36, two storeys, roof run cols 34-44 (row 3) | 352x224 | 1 | 1 | Codex |
| `elder_house_facade` | square, door col 50, roof run cols 46-55 (row 5) | 320x192 | 1 | 1 | Codex |
| `bakery_facade` | lane west, door col 12, awning, roof run cols 8-16 (row 6) | 288x176 | 1 | 1 | Codex |
| `empty_house_facade` | lane west, door col 30, boarded, roof run cols 26-35 (row 5) | 320x176 | 1 | 1 | Codex |
| `mill_house`, `water_wheel` | mill; the wheel stands in the river | 192x192, 96x96 | 1, 12 | 1 | Codex; Codex + bake (45°) |
| `cistern_well_head` | square, frames the shaft and its stone rim, cols 26-33 | 256x112 | 1 | 1 | Codex |
| `window_light_small`, `_large` | on facade panes | 12x16, 16x24 | 3 | 1 | Codex + PixelLab |
| `chimney_smoke` | on each chimney | 24x64 | 8 | 1 | procedural |
| `tavern_sign` | mug pictogram on a bracket | 32x40 | 4 | 1 | Codex + PixelLab |
| `bunting`, `flag` | flags | 128x24, 32x32 | 6 | 1 | Codex + PixelLab |
| `laundry_line` | between two posts | 128x48 | 6 | 1 | Codex + PixelLab |
| `market_stall_bread`, `_apples` | lane west | 112x80 | 1 | 1 | Codex |
| `lantern_post`, `wall_lantern` | street light | 16x80, 16x24 | 3 | 1 | Codex + PixelLab |
| `cart`, `woodpile`, `chopping_block` | | 96x48, 64x32, 24x24 | 1 | 1 | Codex |
| `barrel`, `barrel_stack`, `crate`, `sacks` | | 24x32, 48x48, 24x24, 32x24 | 1 | 1 | Codex |
| `fence_wood_a`, `_b` | 2 cells | 64x32 | 1 | 1 | Codex |
| `flower_box`, `flower_pots` | under windows, by doors | 32x16, 32x24 | 1 | 3 | Codex + edits |
| `bush`, `grass_tuft` | sway | 48x32, 32x16 | 1, 4 | 3 | Codex (+ PixelLab) + edits |
| `village_tree` | still | 128x160 | 1 | 3 | Codex + edits |

Interiors (`interior` biome, 1 band): tavern `tavern_counter` (draws the cols 9-14 solid cells of
row 20, its top on the cells' top: 192x32), `bottle_shelf` 64x64, `table_round` 48x32, `chair`
16x24, `stool` 16x16, `hearth` 64x80 (6 fire frames), `keg_rack` 64x48, `hanging_lamp` 16x32 (3),
`bed` 64x32, `candle` 8x12 (3); bakery `bread_oven` 80x80 (6), `flour_sacks` 48x32, `bread_shelf`
64x64, `kneading_table` 64x32; elder `bookshelf` 48x80, `armchair` 32x40; Ivo's house `guitar`
16x40, `child_bed` 48x32, `cupboard` 48x64.

Inhabitants (64x64 unless noted, 8 frames, 1 band): `taverner` (wiping a mug), `patron_a`
(drinking, standing), `patron_b` (seated), `baker` (kneading), `elder` (leaning on a cane),
`child_a`, `child_b` (48x48, playing), `farmer` (carrying a sack), `water_carrier` (at the well).
Animals: `cat` 32x32 (tail, 6), `cat_roof` 32x16 (breathing, 4), `chicken_a`, `_b` 24x24 (pecking,
8), `bird_roof` 16x16 (4), `dog_sleeping` 48x32 (breathing, 4). WORLD-11 picks who gets
`min_baseline` 0.7.

## Consequences and risks

- WORLD-07 inherits two obligations: `[back]` at z -20, and two collision-only legend characters
  for surfaces a prop draws (inside its own `FORMAT_VERSION` bump).
- Facades must be redrawn when a greybox ledge moves; each contract names the ledge row it matches.
- Baked rotation is stepped (12 to 16 frames per period). Runtime rotation stays possible as a
  second output of `AmbientMotion` if the user prefers smooth sails off the 1x grid.
- Frame cycles are discrete: at memory 0.1 a 6 fps idle flips a frame about every 1.7 s, which
  reads as jerky rather than stopped; the 0.05 threshold does not stop it (question 1).
- A villager is never in the creature pass, so the lesson's `Dim` darkens villagers with the world.
- About 100 textures per dressed room; if draw calls show in a profile, a biome atlas can be built
  at import without changing the contracts.

## Questions for the user

1. A frame cycle in a nearly forgotten place: slow motion all the way down to 0 (the water's rule,
   "not 100% still in the grey"), or stopped below a threshold (`MemoryClock`'s 0.05, or higher,
   e.g. 0.2, so a villager in a well of forgetting truly stands mid-gesture)?
2. Windmill sails and the water wheel: stepped baked frames on the 1x grid (recommended), or
   smooth runtime rotation off the grid?
3. "All doors": the square's building over cols 16-27 and the river mill have no `E` in the
   greybox. Give them doors and interiors, or move them into the backdrop?

## Status (2026-10-09)

BUILT, the core: `AmbientMath`, `AmbientMotion`, `RegionPresence`, `prop_seasonal_material.tres`, `Backdrop.Z` -30, their tests and a demo flag (`systems/props`). Still to come with WORLD-11's art: the contract keys (`bands`, `palette`, `anchor`), PixelLab v2 commands, `bake_rotation.gd`, `prop_scenes_test` and `contents_layering_test`.

## User decisions (2026-10-09)

- Frame cycles in the grey: "Stop below 0.2 memory" - `AmbientMotion` advances only where the memory at its point is at least 0.2.
- Windmill sails and the water wheel: "Baked pixel frames" (`tools/art/bake_rotation.gd`), never runtime rotation.
- The square's middle building and the river mill: "Give both doors and interiors" (two more village interiors, WORLD-11).
- Pixel snapping: "Turn snapping on" - the project now reads `rendering/2d/snap/*` (`bugs/the-project-snap-settings-are-at-a-path-godot-never-reads`).
