---
id: architecture/water-is-world-art-reflecting-two-passes
type: architecture
title: Water lives in the world canvas per body and reflects the world copy plus the creature pass, mirrored in world space
status: active
tags: [water, shader, reflection, screen-texture, creature-pass, pixel-art]
related: [architecture/memory-field-cpu-gpu-split, architecture/memory-runs-through-pause, bugs/creature-pass-frozen-transform-floats-bodies, gotchas/screen-texture-copy-scope]
created: 2026-09-22
updated: 2026-09-23
source_files:
  - scenes/world/environment/water/water_body.gd
  - scenes/world/environment/water/water_surface.gdshader
  - scenes/world/environment/water/water_veil.gdshader
  - scenes/world/environment/water/water_common.gdshaderinc
  - scenes/world/memory/creature_mask.gd
---

## Context

Design 03 §6 wants computed water that reflects "the world above it". Two facts of this
codebase made the obvious designs wrong:

- SILHOUETTE creatures (Ivo, both guardians) are culled out of the root viewport
  (`greyhush_renderer.gd:117`) and composited after the greyhush by the `CreatureMask`
  pass, so a world shader's screen texture never contains them - and they are drawn over
  everything, so they could never look submerged.
- The camera zooms (1.5 on focus, a 1.15 push-in that runs UNDER A PAUSE), so the old
  pre-implementation plan's "world px == screen px, mirror from UV alone" was invalid.

## Options considered

- **One screen-space WaterPass after `Creatures`.** Sees everything, but draws over the
  greyhush (water would need its own grey), needs every body's geometry as uniform arrays,
  ignores foreground order and grows into a god-pass. Rejected.
- **Per-body world-canvas water reading only `hint_screen_texture`.** Correct for the
  world, blind to Ivo. Incomplete.
- **Mirror from a CPU-uploaded camera transform.** Stale under a pause - the same failure
  as `bugs/creature-pass-frozen-transform-floats-bodies`. Rejected.
- **Chosen:** per-body world-canvas water at `WaterQuad.Z` (50), reflecting the automatic
  screen copy PLUS the creature pass (published by `CreatureMask` as the
  `greyhush_creature_pass` global), with the mirror computed in world space.

## Decision

- The mirrored point is found in world space and carried to the screen by the local scale
  taken from derivatives: `SCREEN_UV + (m - world_pos) * uv_per_world`. Measured against
  the exact `SCREEN_MATRIX * CANVAS_MATRIX` projection: under half an output pixel at zoom
  1, 1.15 and 1.5. Nothing is uploaded per frame.
- Two snaps: art decisions in world texels (so the reflection is blocky at art resolution
  under any zoom), fetches at output-pixel centres (the copy is at window resolution).
- Creature pixels are premultiplied and composite "over" the world sample.
- Submersion of SILHOUETTE bodies is `WaterVeil`: a `blend_mul` quad on the creature layer
  sharing `water_common.gdshaderinc`. Multiply keeps transparent pixels transparent and
  needs no screen read. HALO bodies are submerged by the surface quad itself.
- The authored reflection strength is posterised; the Bayer stipple is spent only where
  it FADES (memory between `reflect_memory_low` and `high`, and the screen edge). Dithering
  the whole reflection read as a checkerboard on top of the greyhush's own dither.
- `mirror_axis_offset` is a per-instance export distinct from the surface: water `b` px
  below a bank uses `-b/2`, so the reflection starts at the bank's top (the user's
  reference strip).

## Consequences

- One screen copy per layer serves every body; water never reflects water, nor anything
  at z > 50 (put foreground there on purpose).
- A creature's reflection is greyed by the WATER's memory (the world greyhush pass), not
  by its own shield.
- Anything new that should be reflected must draw below z 50.
- A water rect must stay inside its pit: at z 50 it covers any bank tile it overlaps.
