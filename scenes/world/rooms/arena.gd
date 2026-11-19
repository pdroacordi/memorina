class_name Arena extends Area2D

## Defines guardian movement bounds independently of camera bounds; monitoring is off because this is geometry.

@onready var _shape_node: CollisionShape2D = $CollisionShape2D


## World-space rectangle that confines the fight.
func bounds() -> Rect2:
	# Read before its own _ready too: a guardian earlier in the tree asks from its _ready.
	var node := _shape_node if _shape_node != null else $CollisionShape2D as CollisionShape2D
	var shape: RectangleShape2D = node.shape
	return Rect2(node.global_position - shape.size * 0.5, shape.size)
