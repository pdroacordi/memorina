---
id: architecture/memory-field-cpu-gpu-split
type: architecture
title: MemoryField answers the CPU side, GreyhushRenderer feeds the GPU side — and the math is duplicated on purpose
status: active
tags: [greyhush, memory-field, shader, cpu-gpu-split]
related: [gotchas/glsl-gdscript-math-must-be-duplicated]
created: 2026-09-20
updated: 2026-09-20
source_files:
  - scenes/world/memory/memory_field.gd
  - scenes/world/memory/greyhush_renderer.gd
  - scenes/world/memory/memory_field_math.gd
  - scenes/world/memory/greyhush_common.gdshaderinc
---

## Summary

`MemoryField` (found by group in `game.tscn`) is the CPU-side source of truth for the
world's memory value (0–1 per `docs/design/03_mundo_e_ambiente.md` §2–4). It never learns
it is being drawn. `GreyhushRenderer` is the only place that converts world coordinates
into game pixels and draws the result.

## Details

- The field at 0 is not a colour filter — it is STOPPED. A branch caught mid-sway stays
  caught and resumes from exactly there when colour returns. Lowering an animation's
  amplitude is the wrong fix; see `MemoryClock` for the actual mechanism (drives a
  neighbour's `speed_scale`, and asserts in `_ready()` that its target has no `Character`
  ancestor — characters never freeze).
- The CPU field is a clean disc; the dithered, ragged edge is GPU-only. Nothing in
  gameplay may depend on where a ragged sector happened to fall.
- The boundary dither is computed in game-pixel space (`UV * game_size`), never
  `FRAGCOORD` — the project stretches with integer scaling, so `FRAGCOORD` would dither
  at window resolution and the speckle would change size with the window.

## Why

Separating "what the world's memory value is" (CPU, gameplay-relevant, deterministic)
from "how it looks" (GPU, purely cosmetic, allowed to be dithered/ragged/re-rolled) means
gameplay code can never accidentally depend on a rendering artifact.

## Gotchas / pitfalls

- See [gotchas/glsl-gdscript-math-must-be-duplicated](../gotchas/glsl-gdscript-math-must-be-duplicated.md) —
  changing the falloff/influence formula on one side without the other silently
  desyncs what the game *does* from what it *shows*.
- New field sources compose `MemorySource`; new world effects compose `SongReceiver`.
  Neither requires touching the field/renderer/shader code — if a change to a new source
  or receiver is touching `greyhush_renderer.gd`, that's a sign it should have been a
  `MemorySource`/`SongReceiver` instead.
