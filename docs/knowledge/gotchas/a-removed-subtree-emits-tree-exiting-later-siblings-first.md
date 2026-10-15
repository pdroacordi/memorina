---
id: gotchas/a-removed-subtree-emits-tree-exiting-later-siblings-first
type: gotcha
title: Removing a subtree emits tree_exiting on every node in it, later siblings first, so a handler can run on a node already out of the tree
status: active
tags: [godot, tree, signals, scene-swap, tween]
related: [bugs/a-beat-that-ends-resumes-the-talk-without-the-start-gates, gotchas/an-area2d-emits-body-exited-when-disabled-or-removed, architecture/the-life-loop-rewinds-by-reloading]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - scenes/world/dialogue/dialogue_director.gd
  - scenes/world/scene_swap.gd
---

## Summary

`remove_child(game)` (which `SceneSwap.replace` does on every death and on quit to title) emits `tree_exiting` on every descendant. Children exit before their parent, and siblings exit in reverse order: the later sibling goes first. A handler connected to one node's `tree_exiting` can therefore run on a receiver that has already left the tree.

## Details

Measured on Godot 4.7.2, headless. Tree `Game/World/{Region/Beat, Director}`, `Director` added after `Region`. `root.remove_child(game)` printed "director exiting" before "beat exiting". Inside the beat's handler, `director.is_inside_tree()` was false, and `director.get_tree()` pushed `Parameter "data.tree" is null` and returned null. `director.create_tween()` still returned a Tween, through the `SceneTree` singleton and bound to the out-of-tree node, so it never steps.

Autoloads such as `SaveSystem` stay in the tree. A handler that writes the save from such a callback still succeeds, and it runs after any work done before the swap: in `Game._on_player_died`, the death's rewind.

## Gotchas / pitfalls

- Treat `tree_exiting` of a node you do not own as "maybe the whole world is going". Check `is_inside_tree()` on the receiver, or `is_queued_for_deletion()`, before acting on it.
- Do not use a far node's `tree_exiting` to resume gameplay. It also fires for a scene swap, not only for a room unloading.
