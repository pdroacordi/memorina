class_name LocomotionComponent
extends Node
## Applies ground and air locomotion to its parent body.

@export var stats: LocomotionStats

# Must remain a direct child of the body whose velocity it updates.
@onready var _body: CharacterBody2D = get_parent()


## Wind shifts the target velocity so braking does not fight an added force.
func ground_update(delta: float, axis: float, wind_x: float = 0.0) -> void:
	var drift := ground_drift(wind_x)
	if is_zero_approx(axis):
		_body.velocity.x = move_toward(_body.velocity.x, drift, stats.deceleration * delta)
	elif is_zero_approx(_body.velocity.x) or signf(_body.velocity.x) == signf(axis):
		_body.velocity.x = move_toward(_body.velocity.x, axis * stats.move_speed + drift, stats.acceleration * delta)
	else:
		_body.velocity.x = move_toward(_body.velocity.x, axis * stats.move_speed + drift, stats.deceleration * delta)

func air_update(delta: float, axis: float, wind_x: float = 0.0) -> void:
	var drift := wind_x * stats.air_wind
	if is_zero_approx(axis):
		_body.velocity.x = move_toward(_body.velocity.x, drift, stats.deceleration * stats.air_brakes * delta)
	else:
		_body.velocity.x = move_toward(_body.velocity.x, axis * stats.move_speed + drift, stats.acceleration * stats.air_control * delta)

## Applies vertical wind acceleration; call after gravity.
func lift_update(delta: float, wind_y: float) -> void:
	_body.velocity.y += wind_y * stats.wind_lift * delta

## Returns ground drift after applying the wind deadzone and grip.
func ground_drift(wind_x: float) -> float:
	var excess := maxf(absf(wind_x) - stats.wind_deadzone, 0.0)
	return signf(wind_x) * excess * stats.wind_grip
