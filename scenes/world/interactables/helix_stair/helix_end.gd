class_name HelixEnd extends Area2D

## One end of a HelixStair, on the climbable layer so a rider's climb sensor finds it (ClimbComponent skips it).

var stair: HelixStair
## True at the head, the upper end.
var at_head := false


func _init() -> void:
	collision_layer = Climbable.LAYER
	collision_mask = 0
	monitoring = false
