class_name WaterVolume extends Area2D

## Where bodies meet the water. It knows nothing about the surface: it reports a
## body falling in as a discrete `splashed`, and answers - when asked - who is
## wading through right now. Any CharacterBody2D splashes, so a guardian landing
## in a pool disturbs it exactly as Ivo does, with no wiring to either.

## A body fell into the water. `speed` is its downward speed, in pixels per
## second, at the moment it crossed in.
signal splashed(world_x: float, speed: float)

## Slowest fall that counts as a splash. Also what keeps a body that simply
## starts inside the water (a room loading around it) from splashing.
var min_speed := 120.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

## Every body in the water now, as (x, horizontal speed): the wake is polled
## each physics frame, never signalled, because it is a level and not an event.
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
