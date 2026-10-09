---
id: bugs/a-canvas-pass-re-added-to-the-tree-stops-culling-its-bit
type: bug
title: A CanvasPass removed and re-added to the tree restores its bit to the root cull mask and never removes it again, so its layer draws twice
status: resolved
severity: low
tags: [rendering, subviewport, canvas-pass, cull-mask, lifecycle, mem-12]
related: [systems/foreground, architecture/foreground-layer]
created: 2026-10-09
updated: 2026-10-09
source_files:
  - scenes/world/memory/canvas_pass.gd
---

## Summary

`CanvasPass` clears its bit from the root's `canvas_cull_mask` in `_ready`, which runs once, and
restores it in `_exit_tree`, which runs on every exit. After a remove and re-add, the root keeps
drawing that layer. Creatures or foreground pieces are then drawn both in the world canvas and
in their pass.

## Symptom

Found in the MEM-12 review. Latent: nothing in the game removes and re-adds a pass today.
`SceneSwap` frees `game.tscn`, so the next game gets fresh passes. Measured with a headless probe
(4.7.2, layer 4): mask 0xFFFFFFFF, add gives 0xFFFFFFFB, remove gives 0xFFFFFFFF, and re-add
leaves it at 0xFFFFFFFF.

Had it happened, the world pass would draw Ivo under the greyhush (so the water would reflect him
twice), and foreground pieces would land in the screen copy (so the lake would reflect them, which
`systems/water` forbids).

## Root cause

`scenes/world/memory/canvas_pass.gd:50` (`root.canvas_cull_mask &= ~layer`) is in `_ready`.
`:56` (`|= layer`) is in `_exit_tree`. The same file's `_enter_tree` comment (`:32`) already names
this exact case for the shader global and moved that write to `_enter_tree` because of it.

## Fix

Not fixed. Move the `&= ~layer` to `_enter_tree`, next to the global, so the two writes pair
enter/exit. `get_tree().root` is valid there.

## Prevention

The planned `canvas_pass_test` (architecture/foreground-layer, Tests) was not written. Add it
with this case: remove and re-add a pass, then assert the bit is culled. Add the other planned
cases too: two passes freed in either order, and the global set and cleared.

## Resolution (2026-10-09)

`CanvasPass` removes its bit in `_enter_tree` (every entry) and gives it back in `_exit_tree`; `canvas_pass_test.test_a_pass_re_added_culls_its_bit_again` pins it.
