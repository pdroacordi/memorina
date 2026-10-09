---
id: architecture/foreground-layer
type: architecture
title: The foreground is a second canvas pass drawn over the creatures, shaded by the creature composite's shader, with centre-anchored parallax and a whole-piece fade (MEM-12)
status: active
tags: [foreground, rendering, subviewport, creature-pass, greyhush, seasonal-art, parallax, fade, lesson, plan, mem-12]
related: [architecture/memory-field-cpu-gpu-split, architecture/water-is-world-art-reflecting-two-passes, architecture/memory-runs-through-pause, bugs/creature-pass-frozen-transform-floats-bodies, bugs/creature-pass-bilinear-blur, gotchas/subviewport-does-not-inherit-default-texture-filter, gotchas/screen-texture-copy-scope, gotchas/parallax2d-ignores-its-parents-offset, gotchas/glsl-gdscript-math-must-be-duplicated, systems/greyhush, systems/seasonal-art, systems/water, systems/songs-and-the-memorina, systems/rooms]
created: 2026-10-08
updated: 2026-10-08
source_files:
  - scenes/world/game.tscn
  - scenes/world/memory/creature_mask.gd
  - scenes/world/memory/greyhush_renderer.gd
  - scenes/world/memory/greyhush_creatures.gdshader
  - scenes/world/memory/greyhush_common.gdshaderinc
  - scenes/world/memory/seasonal/seasonal_art.gdshader
  - scenes/ui/lesson_cinematic/lesson_cinematic.tscn
  - scenes/characters/character.gd
  - tools/stack_seasonal_sheets.gd
---

## Summary

BUILT (2026-10-09, MEM-12; `systems/foreground`). Differences from the plan: the composite shader keeps its name `greyhush_creatures.gdshader` (only the script was renamed, to `canvas_pass.gd`); `stack_seasonal_sheets.gd` does not stack foreground sheets yet (with the biome art); the demo pieces are flat placeholders in the spring trial only. Plan (2026-10-08, design 04 §6 "Primeiro plano"): Foreground pieces are `ForegroundPiece`
sprites in a room's contents scene, on their own visibility bit, rendered by a second
`SubViewport` pass (`CreatureMask` generalised into `CanvasPass`) and composited after
`Creatures` with the creature composite's shader (`clipped_pass = false`), so a branch greys and
re-colours from the same `greyhush_common` code as the world. Seasons come from the existing
`seasonal_art.gdshader` (the mask is screen-space). Parallax is a pure, centre-anchored offset
(immune to the WORLD-04 region offset); a piece fades as a whole while a character stands behind
it. `LessonCinematic` moves above the foreground and its dim leaves holes only where a creature
shows uncovered. The pass is culled from the root, so water never reflects it.

## Context

- SILHOUETTE creatures (Ivo, guardians) are culled from the root (`creature_mask.gd:10`) and
  composited by `CanvasLayer/Creatures` after `Greyhush`. Nothing in the world canvas can cover
  them, whatever its z.
- The greyhush is screen-space: background parallax layers are already greyed by the memory at
  their screen pixel, not their depth. A foreground piece greyed by its screen pixel matches them.
- `seasonal_art.gdshader` samples `greyhush_season_mask` at `SCREEN_UV`; a SubViewport the size of
  the root's visible rect (as `CreatureMask` is) gives the same mapping.
- `LessonCinematic` (Dim, letterbox bars, title card) sits between `Greyhush` and `Creatures`, so
  the dim spotlights the bodies; anything drawn after `Creatures` escapes the dim and covers the bars.
- `Parallax2D` positions from the camera's GLOBAL top-left (`gotchas/parallax2d-ignores-its-parents-offset`);
  the trials sit at x 0 to 14912.

## Options considered

Render route:
- **z above everything in the world canvas.** Always under SILHOUETTE creatures. Rejected.
- **Draw it inside `CreatureMask`, on top.** Gets creature shading (Ivo's clipped shield would
  colour a pillar in front of him), the `WaterVeil` multiply, and is reflected through
  `greyhush_creature_pass`. Rejected.
- **A `CanvasLayer` (follow_viewport) after `Creatures` with a greyhush material per piece.** Every
  source/shield array pushed to each material per frame. Also, `Creatures`, the HUDs and the
  cinematic share one `CanvasLayer`, so a layer cannot sit between them without splitting
  `game.tscn`. Rejected.
- **Chosen: a second canvas pass, the creature pass's own code**, with a second material of the
  creature composite shader.

Parallax:
- **`Parallax2D` + `scroll_offset` compensation.** The compensation depends on where the region is
  placed. Top-left reference under the focus zoom is unmeasured. Rejected for foreground.
- **Offset in the vertex shader.** Exact per frame, but the item is culled by its CPU rect (pieces
  pop at the screen edge), and the fade would need the same formula in GDScript. Rejected.
- **Chosen: a pure CPU offset from the view centre**, applied by the piece.

Lesson dim:
- **A `veil` uniform on the foreground composite pulled from the dim.** Still draws branches over
  the letterbox bars. Rejected.
- **Hide the foreground during calls and lessons.** Cheaper, but the trees in front vanish when a
  guardian calls. Rejected.
- **Chosen: move `LessonCinematic` above `Foreground` and cut the dim where a creature shows.**

Fade:
- **A per-pixel x-ray hole from the creature pass.** Only SILHOUETTE bodies, and it flickers with
  the animation. Rejected.
- **Alpha-bitmap coverage.** Needs CPU images for every band. Rejected; `reveal_rect` handles sparse art.
- **Chosen: whole-piece alpha from the overlap of rects.**

Authoring:
- **A `.room` entity.** Parallax pieces are not on the grid, and art carries no gameplay meaning.
  Rejected. Contents scene, beside the backgrounds.

## Decision

- **`CanvasPass extends SubViewport`** (rename `creature_mask.gd` to `canvas_pass.gd` in the
  FileSystem dock). Exports `@export_flags_2d_render var layer: int` and `@export var global_name: StringName`.
  Consts `CREATURES := 2`, `FOREGROUND := 4`. `static func join_layer(item: CanvasItem, layer: int)`.
  `_ready` also mirrors the root's `snap_2d_transforms_to_pixel` / `snap_2d_vertices_to_pixel`
  (unverified whether a SubViewport inherits them; same family as the filter gotcha). **Each pass
  owns its bit of the root mask**: `root.canvas_cull_mask &= ~layer` in `_ready`, `|= layer` in
  `_exit_tree`. `GreyhushRenderer` drops its two `canvas_cull_mask` writes.
  `game.tscn`: `CreatureMask` (layer 2, `greyhush_creature_pass`) and a new **`ForegroundPass`**
  (layer 4, `greyhush_foreground_pass`) after `SeasonMask`. Both ALWAYS: a pass mirrors the camera.
- **`greyhush_creatures.gdshader` becomes `greyhush_overlay.gdshader`** (rename; header: "an isolated
  pass over the drained world"). New `greyhush_foreground_material.tres` uses it.
  `GreyhushRenderer`: `@export var foreground_pass_path: NodePath`. `_set_param` loops over the
  materials collected in `_ready`, and the foreground's `clipped_pass` is false.
- **`CanvasLayer` order:** `Greyhush`, `Creatures`, **`Foreground`** (TextureRect, ViewportTexture
  of `ForegroundPass`, nearest filter, mouse ignore), **`LessonCinematic`** (moved), `MemorinaHud`,
  `RecallPrompt`, `GuardianCallHud`, `Fade`, `LifeHud`, `SaveMark`, `NotebookToast`.
- **`lesson_dim.gdshader`** on `LessonCinematic/Dim`:
  `COLOR.a *= 1.0 - creature.a * (1.0 - front.a)`, both read at `SCREEN_UV` from the two globals.
  This is exact for binary alpha. A body behind a faded piece (alpha 0.3) is dimmed 30%.
  `lesson_cinematic.gd` is unchanged. The bars and the card now cover bodies too.
- **`ForegroundPiece extends Sprite2D`** (`scenes/world/environment/foreground/`). Its authored
  position is the anchor, and its parent must have no rotation or scale (asserted). `_ready`:
  `join_layer(self, FOREGROUND)`, `process_mode = ALWAYS`, and `set_process(false)` when
  `scroll_scale == ONE and not reveals`. `_process` calls
  `update_for(view_centre, body_rects, delta)`, a public seam for tests. Exports:
  - `scroll_scale: Vector2 = ONE`, range 1..2: screen speed relative to the play plane (1 = same depth).
  - `reveals: bool = true`: fades while a character stands behind it.
  - `faded_alpha: float = 0.3` (0..1).
  - `fade_time: float = 0.25`: scaled seconds from opaque to faded. A hold stops it.
  - `reveal_coverage: float = 0.15`: fraction (0..1) of a body's rect that must be covered.
  - `reveal_rect: Rect2`: local px; empty means `get_rect()`.

  Bodies are `Character.CHARACTERS_GROUP` members that are visible in the tree. The fade ignores
  memory: it is readability, not world time.
- **`ForegroundMath` (RefCounted, pure):**
  - `view_centre(canvas: Transform2D, viewport_size: Vector2) -> Vector2`
  - `parallax_offset(anchor, view_centre, scroll_scale) -> Vector2` = `(scroll_scale - 1) * (anchor - view_centre)`
  - `coverage(area: Rect2, body: Rect2) -> float`
  - `fade_toward(alpha, target, faded_alpha, fade_time, delta) -> float`
- **`Character`:** `const CHARACTERS_GROUP := &"characters"` (it cannot be named `GROUP`, because
  `Player` and `Guardian` already declare that), joined in `_ready`, and
  `body_rect() -> Rect2` from its `CollisionShape2D`.
- **Authoring:** a plain `Foreground` Node2D in `<room>_contents.tscn`, nearest piece last (tree
  order is draw order inside the pass). Three-band pieces wear `seasonal/foreground_seasonal_material.tres`
  (`band_count` 3, `(2, 0, 1, 0)`, `distance` 0) with `region_rect` on band 0. One-band pieces wear none.
- **Water:** nothing. The pass is not in the screen copy or in `greyhush_creature_pass`, so the
  foreground is never reflected and covers water like any later draw.

## Consequences

- One formula: the foreground composite is the creature shader. No GLSL or GDScript twin is added.
  `parallax_offset` is GDScript only.
- SOLID: `CanvasPass` is one class with two instances configured by exports (open/closed). The
  piece is glue and the math is pure (single responsibility). Each pass owns its own cull bit.
  The cinematic pulls two globals and knows no nodes.
- Cost: a 640x360 RGBA8 target (0.9 MB), a canvas walk, and a full-screen composite that exits
  early on transparent pixels. That is about the creature pass again. Measure it with
  `RenderingServer.viewport_set_measure_render_time` and record the result in `systems/foreground`.
  Do not idle the pass when a room has no pieces: the dim would then read a stale texture.
- Inherited limit: the pass renders at game resolution, so at zoom 1.5 and 1.15 its pixels are as
  uneven as the creatures' pixels.
- WORLD-06 may reuse `parallax_offset` for backgrounds (scroll_scale < 1 is the same formula).
- Files: the renames and new files above. Changes to `greyhush_renderer.gd`, `greyhush_shield.gd`,
  `water_quad.gd`, `rain_fall.gd` (`CanvasPass.join_layer(x, CanvasPass.CREATURES)`),
  `character.gd`, `game.tscn`, `lesson_cinematic.tscn`, `project.godot`
  (`greyhush_foreground_pass` global; 2d_render layer names world/creatures/foreground), and
  `tools/stack_seasonal_sheets.gd` (also stacks `foreground/<biome>/<season>/<name>.png` into
  `foreground/<biome>/seasonal/<name>.png`, falling back to spring). Demo pieces go in
  `spring_trial_contents.tscn` (x 7200, which tests the offset) and over the water trial's lake.
- Docs on build: new `systems/foreground` plus its `CLAUDE.md` row ("Never break: foreground draws
  only in `ForegroundPass`, after `Creatures`, shaded by `greyhush_overlay`; never in the root
  canvas"). Also update `systems/greyhush`, `systems/seasonal-art`, `systems/water`
  (`CreatureMask.join_layer`), the pause-mode map (`ForegroundPass`, `ForegroundPiece`), the
  `greyhush_shield.gd` doc comment, the glossary (primeiro plano), and a Revision on
  `water-is-world-art-reflecting-two-passes` ("z > 50" is for world art covering water; the
  foreground is a pass).
- Tests:
  - `foreground_math_test`: offset is zero at scale ONE and at the anchor; scale 1.5 with the
    centre 100 px left gives +50; screen speed is scale x world speed; anchor and centre both
    +7200 give the same offset; scale (1.3, 1) leaves y alone; coverage for disjoint (0), inside
    (1), half (0.5) and a zero-area body (0); fade rate, clamp, `fade_time` 0 snaps, delta 0 holds.
  - `foreground_piece_test`: only bit 4 on the piece, and the parent keeps its bits plus 4;
    `update_for` places the piece and fades it in and out; `reveals` false holds alpha 1;
    ALWAYS after ready.
  - `canvas_pass_test`: cull bit removed and restored; two passes freed in either order leave the
    mask right; the global is set and cleared; filter and snap match the root.
  - `foreground_pieces_test` (every `*_contents.tscn`): scale in 1..2; a seasonal piece's region is
    band 0; textures under `assets/sprites/world/foreground/`; no `CollisionObject2D` inside.
- Playtests:
  - a pulse edge across a same-depth piece and the world behind it while panning, with no
    one-frame offset (this also checks sibling SubViewport order for the season mask);
  - a near branch scrolling at 1.4 with no jitter (checks the camera transform timing; fallback:
    `process_priority`);
  - walking behind a column fades it;
  - F9 lesson: the dim and the bars cover the foreground, and Ivo stays lit;
  - the lake does not reflect the piece.

## Art contract (foreground pieces)

- 1x (one art pixel = one game pixel), transparent PNG with binary alpha, the `style.md` outline,
  palette snapped (`process_image.gd`). Never scale a piece to sell depth; depth is parallax.
- Nature pieces (branches, ferns, wheat, leaves, rocks, icicles, burnt roots) have three equal bands,
  spring / autumn / winter from top to bottom, authored one season per file and stacked. Summer
  uses spring. Built pieces (fences, laundry lines, columns, beams, curtains) have one band (04 §6).
- Size: a band at most 640 x 240 px for near pieces. A one-band column at most 1024 px tall. Every
  sheet at most 2048 px per side. Crop tight to the opaque mass (it is the default reveal rect).
- Near pieces (scale > 1) use the darker half of the palette and no detail finer than 2 px.
  Same-depth occluders use the play-plane palette. Low-frequency shapes only: the grey stays empty.
- Density: at most about 20% of any frame. Near pieces stay in the top quarter and bottom fifth,
  except thin verticals of 32 px or less. Same-depth occluders over walkable ground are at most
  64 px wide. Never over a hazard edge, a landing, a bench, a door or a song interactable.
- Each piece gets a contract `tools/art/prompts/<id>.md` whose target is its spring file (or its
  only file). Other seasons are drawn from it as a reference (our own art) into their season
  folders. MEM-12's demo art may use flat placeholders with one distinct hue per band, so the
  swap is visible.

## Risks

- The `ForegroundPass` may render before `SeasonMask` (a one-frame mask lag on pieces). Keep it
  after `SeasonMask` in the tree and verify with the pulse-edge probe.
- The SubViewport snap defaults (above). If a SubViewport does not inherit them, `CreatureMask` has
  had the same latent defect.
- An ancestor that draws (debug collision shapes) also draws in the foreground pass, because
  `join_layer` ORs the bit up the tree. This affects debug only.
- The CreatureMask to CanvasPass rename touches four scripts and several docs. Do it in the editor.
