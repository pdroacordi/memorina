class_name Spawner
extends Node2D

const GROUP := "spawner"

func _enter_tree() -> void:
	add_to_group(GROUP)

## Frees every spawned instance. Call on room transitions so effects from
## the previous room don't linger into the next one.
func clear() -> void:
	for child in get_children():
		child.queue_free()

func spawn(scene: PackedScene, global_pos: Vector2 = Vector2.ZERO) -> Node:
	var instance := scene.instantiate()

	# global_pos only applies when the scene's root is spatial: a non-Node2D
	# root (e.g. a bare Node orchestrating other nodes) has no position to set,
	# so the caller's global_pos is silently ignored in that case.
	var node_2d := instance as Node2D
	if node_2d != null:
		node_2d.position = to_local(global_pos)

	add_child(instance)
	return instance
