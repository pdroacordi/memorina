class_name SceneSwap
extends RefCounted
## Replaces a scene in place by remove, free and add; never `reload_current_scene()`, which under the playtest harness reloads the runner.


## Swaps `old` for a fresh instance of `packed` at the same index and re-points `current_scene`; returns the new scene.
static func replace(old: Node, packed: PackedScene) -> Node:
	var tree := old.get_tree()
	var parent := old.get_parent()
	var index := old.get_index()
	var was_current := tree.current_scene == old
	var fresh := packed.instantiate()
	parent.remove_child(old)
	old.queue_free()
	parent.add_child(fresh)
	parent.move_child(fresh, index)
	if was_current:
		tree.current_scene = fresh
	return fresh
