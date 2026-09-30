class_name Climbable extends Area2D

## Something a body can climb: Enraizar's root webs across a shaft and its
## pillars. It is only a place (an area on the Climbable layer, each of its
## shapes switched on while that part can be held); ClimbComponent is the
## holding. `grip` is how it is held, for the body's pose: a WALL faced from
## the side, a POLE hugged from behind.

enum Grip { WALL, POLE }

## The physics layer climbables live on (layer 3, "Climbable").
const LAYER := 1 << 2

@export var grip: Grip = Grip.WALL

func _init() -> void:
	collision_layer = LAYER
	collision_mask = 0
	monitoring = false
