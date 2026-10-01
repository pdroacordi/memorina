---
id: gotchas/queue-free-deferred-add-still-enters-the-tree
type: gotcha
title: queue_free() does not cancel a pending call_deferred("add_child", node) - the doomed node enters the tree for the rest of the frame
status: active
tags: [queue-free, call-deferred, add-child, groups, room, eviction]
related: [gotchas/queue-free-keeps-the-name-until-frame-end, gotchas/first-process-frame-can-precede-the-first-deferred-flush]
created: 2026-10-01
updated: 2026-10-01
source_files:
  - scenes/world/rooms/room.gd
---

## Summary

The deferred-call flush runs BEFORE the deletion queue in the same frame. So if a node is
`queue_free()`d while a `call_deferred("add_child", node)` for it is still pending, it is
still added. It runs `_enter_tree` and `_ready`, joins its groups, and registers sources
and shelters. Only at the end of the frame is it freed again.

## Details

Measured on 4.7.2: `call_deferred("add_child", child)`, then `child.queue_free()`, in the
same frame. The child's `_enter_tree` ran. The next frame `is_instance_valid(child)` was
false.

`Room.evict()` (room.gd:158-165) guards only the case where the contents are already
parented (`get_parent() == self`). If the contents are still waiting on `activate()`'s
deferred `add_child`, it only calls `queue_free()`, and the doomed contents still enter
the tree for one frame. During that frame its `Seat` is findable by `Seat.find`, its
`MemorySource`s register with the field, and its `Enemy`s check the ledger. This cannot
happen today: no code path evicts a room in the same frame that activated it. It becomes
possible as soon as something does, for example a rest landing in the frame of a room
swap.

## Gotchas / pitfalls

- Make the deferred step check that it is still wanted. For example, add through a
  method that checks `node == _contents_node and not node.is_queued_for_deletion()`.
  Alternatively, keep the node and cancel by state rather than by freeing.
