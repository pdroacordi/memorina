---
id: systems/greyhush
type: system
title: The greyhush: the memory field and its renderer
status: active
tags: [greyhush, memory-field, shader, dither]
related: [architecture/memory-field-cpu-gpu-split, gotchas/glsl-gdscript-math-must-be-duplicated]
created: 2026-10-02
updated: 2026-10-29
source_files:
  - scenes/world/memory/memory_field.gd
  - scenes/world/memory/greyhush_renderer.gd
  - scenes/world/memory/greyhush_common.gdshaderinc
  - scenes/world/memory/unshielded_mark.gdshaderinc
---

# The greyhush: the memory field and its renderer

Moved verbatim from `CLAUDE.md` ("The greyhush (memory field)") on 2026-10-02.

The world's state at any point is a memory value from 0 to 1 (`docs/design/03_mundo_e_ambiente.md` sections 2-4). **It is not a colour filter.** A place at 0 is not merely grey, it is STOPPED — a branch caught mid-sway stays caught, and resumes from exactly there when colour returns. Lowering an animation's amplitude would be the wrong fix: that still leaves a cycle running.

- **`MemoryField` (in `game.tscn`, found by group) answers the CPU side; `GreyhushRenderer` feeds the GPU side.** The field never learns it is being drawn, and the renderer is the only place that converts world coordinates into game pixels.
- **`MemoryFieldMath.source_distance()` / `disc_influence()` and `gh_shape_distance()` / `gh_influence()` in `greyhush_common.gdshaderinc` are the same formulas written twice**, because GDScript and GLSL cannot share code. Change one and you MUST change the other. Every tunable reaches the shader as a uniform from `MemoryFieldMath`'s constants — never re-type a number into the shader.
- **The dithered, ragged edge is GPU-only.** The CPU field is a clean disc. Nothing in gameplay may depend on where a ragged sector happened to fall.
- **The edge re-rolls on `greyhush_time`, never `TIME`.** `greyhush_time` is a global shader uniform (`project.godot` `[shader_globals]`) that `GreyhushRenderer._process` advances by its scaled delta and wraps at `TIME_WRAP` (3600 s). So it re-rolls (every `edge_reroll_period`, 1.6 s) through a performance freeze, slows with a recall and stops under a menu hold. No shader in the project reads `TIME`; the `verify-gates` scan has no exception. The corrupted creatures' fraying edge re-rolls on the same clock, in the sprite's art pixels (`systems/creatures`). `MemoryFieldMath` has no twin of the wobble, because it is rendering-only.
- **The boundary is an ordered (Bayer) dither, never a gradient**, computed in game-pixel space via `UV * game_size` rather than `FRAGCOORD` — the project stretches with integer scaling, so `FRAGCOORD` would dither at window resolution and the speckle would change size with the window.
- **Unshielded pixels** (CORE-13, 2026-10-29). A SILHOUETTE shield lights every creature-pass pixel inside its shape, not only its owner's. A corrupted creature's pixels carry a mark so no shield lights them: the corruption edge writes alpha `GH_UNSHIELDED_ALPHA` (253/255, `unshielded_mark.gdshaderinc`) on every pixel it draws. The creature composite (`greyhush_creatures.gdshader`, also the foreground composite) shades a marked pixel with `gh_memory_weighted(px, 0.0, ...)`, the field without shield light, and draws it opaque.
  - `gh_memory` and `gh_smooth_memory` are the weight-1 cases, so every other pixel and pass is unchanged.
  - The memory formula did not change, and shields are rendering-only, so `MemoryFieldMath` has nothing to mirror.
  - Draw order resolves overlaps: an opaque sprite drawn over a marked pixel writes alpha 1 and is lit by its own shield.
  - A separate unshielded pass was rejected: it would need its own cull bit and texture for every consumer, and it could not tell who is in front.
  - Accepted leaks: a creature pixel over an opaque Ivo pixel, two creatures overlapping, and an antialiased item whose alpha is exactly 253 (`bugs/ivos-greyhush-shield-colours-a-creature-in-melee-range`).
- **Environment freezes; characters never.** `MemoryClock` drives a neighbour's `speed_scale` from the field and asserts in `_ready()` that its target has no `Character` ancestor.
- **A teacher's shield** (CORE-04, `systems/teaching-creatures`): each teaching creature carries a SILHOUETTE `GreyhushShield` (CIRCLE, `amount` 1.0) and a sprite with no material, so its pixels carry no unshielded mark and its own shield (and Ivo's, in reach) lights it. Its balloon is drawn on the HUD, never greyed.
- New field sources (death marks, flashbacks, the hero's aura in the final fight) compose `MemorySource`. New world effects compose `SongReceiver`. Neither requires touching the song, pulse or field code.
- **The forgotten print outside the greyhush pass is one formula**: `gh_print(rgb)` in `scenes/world/memory/greyhush_print.gdshaderinc` (luma, blacks lifted toward `greyhush_black_lift_color` by `greyhush_black_lift`, the globals `GreyhushRenderer` pushes). `life_note.gdshader` and the title's `title_grey.gdshader` include it; change the print there only. `gh_shade` in `greyhush_common.gdshaderinc` is a different composition (lift weighted by how forgotten, haze, contrast loss) and does not use it.

- **Props** (2026-10-09, WORLD-08): `AmbientMotion` is the frame-cycle twin of `MemoryClock`: a prop's own clock advances by `delta * memory` at its point and stops below 0.2 ("Stop below 0.2 memory", user, 2026-10-09); `systems/props`.
