class_name Room
extends Area2D

@onready var _shape_node: CollisionShape2D = $CollisionShape2D

## World-space rectangle the camera is allowed to show.
func get_bounds() -> Rect2:
	var shape: RectangleShape2D = _shape_node.shape
	return Rect2(_shape_node.global_position - shape.size * 0.5, shape.size)
