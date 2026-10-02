class_name Arena extends Area2D

## Defines guardian movement bounds independently of camera bounds; monitoring is off because this is geometry.

@onready var _shape_node: CollisionShape2D = $CollisionShape2D


## World-space rectangle that confines the fight.
func bounds() -> Rect2:
	var shape: RectangleShape2D = _shape_node.shape
	return Rect2(_shape_node.global_position - shape.size * 0.5, shape.size)
