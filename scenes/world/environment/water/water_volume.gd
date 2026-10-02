class_name WaterVolume extends Area2D

## Reports water entry splashes and currently overlapping character bodies.

## A body fell into the water. `speed` is its downward speed, in pixels per
## second, at the moment it crossed in.
signal splashed(world_x: float, speed: float)

## Slowest fall that counts as a splash. Also what keeps a body that simply
## starts inside the water (a room loading around it) from splashing.
## Minimum downward entry speed that triggers a splash, in pixels per second.
var min_speed := 120.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

## Current CharacterBody2D disturbances as (world x, absolute horizontal speed), polled each physics frame.
func disturbances() -> PackedVector2Array:
	var out := PackedVector2Array()
	for body: Node2D in get_overlapping_bodies():
		var mover := body as CharacterBody2D
		if mover:
			out.append(Vector2(mover.global_position.x, absf(mover.velocity.x)))
	return out

func _on_body_entered(body: Node2D) -> void:
	var mover := body as CharacterBody2D
	if mover and mover.velocity.y >= min_speed:
		splashed.emit(mover.global_position.x, mover.velocity.y)
