---
id: systems/greyhush
type: system
title: The greyhush: the memory field and its renderer
status: active
tags: [greyhush, memory-field, shader, dither]
related: [architecture/memory-field-cpu-gpu-split, gotchas/glsl-gdscript-math-must-be-duplicated]
created: 2026-10-02
updated: 2026-10-02
source_files:
  - scenes/world/memory/memory_field.gd
  - scenes/world/memory/greyhush_renderer.gd
---

# The greyhush: the memory field and its renderer

Moved verbatim from `CLAUDE.md` ("The greyhush (memory field)") on 2026-10-02.

The world's state at any point is a memory value from 0 to 1 (`docs/design/03_mundo_e_ambiente.md` sections 2-4). **It is not a colour filter.** A place at 0 is not merely grey, it is STOPPED — a branch caught mid-sway stays caught, and resumes from exactly there when colour returns. Lowering an animation's amplitude would be the wrong fix: that still leaves a cycle running.

- **`MemoryField` (in `game.tscn`, found by group) answers the CPU side; `GreyhushRenderer` feeds the GPU side.** The field never learns it is being drawn, and the renderer is the only place that converts world coordinates into game pixels.
- **`MemoryFieldMath.source_distance()` / `disc_influence()` and `gh_shape_distance()` / `gh_influence()` in `greyhush_common.gdshaderinc` are the same formulas written twice**, because GDScript and GLSL cannot share code. Change one and you MUST change the other. Every tunable reaches the shader as a uniform from `MemoryFieldMath`'s constants — never re-type a number into the shader.
- **The dithered, ragged edge is GPU-only.** The CPU field is a clean disc. Nothing in gameplay may depend on where a ragged sector happened to fall.
- **The boundary is an ordered (Bayer) dither, never a gradient**, computed in game-pixel space via `UV * game_size` rather than `FRAGCOORD` — the project stretches with integer scaling, so `FRAGCOORD` would dither at window resolution and the speckle would change size with the window.
- **Environment freezes; characters never.** `MemoryClock` drives a neighbour's `speed_scale` from the field and asserts in `_ready()` that its target has no `Character` ancestor.
- New field sources (death marks, flashbacks, the hero's aura in the final fight) compose `MemorySource`. New world effects compose `SongReceiver`. Neither requires touching the song, pulse or field code.
