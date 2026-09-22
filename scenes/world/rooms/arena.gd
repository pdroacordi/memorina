class_name Arena extends Area2D

## Where a fight happens: the stretch of ground a guardian may move and land
## on, authored in the room's contents beside the guardian and handed to it.
##
## Deliberately NOT the camera's bounds, which is what the ROOM lets the frame
## show - a rendering clamp. The two happen to coincide today; letting a boss
## read one for the other means any future cutscene camera moves where it
## comes down. Monitoring is off: this is geometry, not a trigger.

@onready var _shape_node: CollisionShape2D = $CollisionShape2D


## World-space rectangle the fight is confined to.
func bounds() -> Rect2:
	var shape: RectangleShape2D = _shape_node.shape
	return Rect2(_shape_node.global_position - shape.size * 0.5, shape.size)
