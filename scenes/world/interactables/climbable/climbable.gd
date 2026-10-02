class_name Climbable extends Area2D

## A climbable area; ClimbComponent handles holding and `grip` selects the body's pose.

enum Grip { WALL, POLE }

## Physics layer 3, Climbable.
const LAYER := 1 << 2

@export var grip: Grip = Grip.WALL

func _init() -> void:
	collision_layer = LAYER
	collision_mask = 0
	monitoring = false
