class_name FlightComponent
extends Node
## Steers its parent body's velocity toward a desired velocity plus the air's, with no gravity: wind is
## carried, never a force (architecture/one-air-channel).

@export var stats: LocomotionStats

# Must remain a direct child of the body whose velocity it updates.
@onready var _body: CharacterBody2D = get_parent()


## `steer` and `wind` in px/s.
func fly_update(delta: float, steer: Vector2, wind: Vector2) -> void:
	_body.velocity = steered(_body.velocity, steer, wind, stats, delta)

## The velocity after `delta` s: toward `steer + wind * air_wind`, accelerating while steering
## along the way it already moves, decelerating otherwise.
static func steered(velocity: Vector2, steer: Vector2, wind: Vector2, tuning: LocomotionStats, delta: float) -> Vector2:
	var target := steer + wind * tuning.air_wind
	var braking := steer.is_zero_approx() or velocity.dot(target) < 0.0
	var rate := tuning.deceleration if braking else tuning.acceleration
	return velocity.move_toward(target, rate * delta)
