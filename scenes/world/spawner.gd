class_name Spawner
extends Node2D

const GROUP := "spawner"

func _enter_tree() -> void:
	add_to_group(GROUP)

## Frees spawned instances on room transitions.
func clear() -> void:
	for child in get_children():
		child.queue_free()

func spawn(scene: PackedScene, global_pos: Vector2 = Vector2.ZERO) -> Node:
	var instance := scene.instantiate()

	# Only Node2D roots have a global position to apply.
	var node_2d := instance as Node2D
	if node_2d != null:
		node_2d.position = to_local(global_pos)

	add_child(instance)
	return instance
