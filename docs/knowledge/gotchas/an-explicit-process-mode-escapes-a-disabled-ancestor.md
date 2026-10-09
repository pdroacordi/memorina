---
id: gotchas/an-explicit-process-mode-escapes-a-disabled-ancestor
type: gotcha
title: A node with its own PAUSABLE or ALWAYS process mode keeps processing under a DISABLED ancestor
status: active
tags: [process-mode, pause, rooms, ambient, foreground]
related: [systems/props, systems/rooms, systems/songs-and-the-memorina, architecture/props-and-ambient-life]
created: 2026-10-09
updated: 2026-10-09
source_files:
  - scenes/world/rooms/room.gd
  - scenes/world/environment/props/ambient_motion.gd
  - scenes/world/environment/foreground/foreground_piece.gd
---

## Summary

`PROCESS_MODE_DISABLED` stops only the nodes that INHERIT from it. A descendant that sets its own
mode (PAUSABLE or ALWAYS) is its own process owner and keeps running its `_process` and
`_physics_process`. `Room.deactivate()` disables and hides its contents; only the hide reaches
such a node.

## Details

Measured in 4.7.2 (headless, a scratch project, 2026-10-09): a `Node` with
`process_mode = PAUSABLE` under a parent set to `DISABLED` ticked `_physics_process` 9 times in
10 physics frames.

Engine rule: an INHERIT node takes its mode from the nearest ancestor whose mode is not INHERIT.
A node with an explicit mode never looks up the tree, so a DISABLED ancestor does not reach it.

In this project:
- `Room.deactivate()` (`room.gd:43`) sets the cached contents to DISABLED and hides them.
- `AmbientMotion._ready()` (`ambient_motion.gd:26`) forces PAUSABLE, and `ForegroundPiece._ready()`
  forces ALWAYS. Both keep ticking in every deactivated resident room. Each stops early on
  `is_visible_in_tree()`, and that check is what holds them, not the DISABLED mode.
- `architecture/props-and-ambient-life` (section 3) says "a deactivated room's props hold (process
  disabled)". The behaviour is right, but the mechanism it names is wrong.

## Gotchas / pitfalls

- A node that sets its own process mode must also stop itself when its room is unloaded. In
  practice that means an `is_visible_in_tree()` early return as the first line of the callback.
  Deleting or moving that return makes props in unloaded rooms animate, sample the field and write
  frames.
- Anything that disables a subtree without hiding it reaches only the INHERIT nodes. Today only
  `Room` disables a subtree, and it always hides it too.
- The cost per explicit-mode node in every resident room is one callback and one visibility test
  per frame.
