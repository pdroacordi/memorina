class_name LocomotionComponent
extends Node
## Applies ground and air locomotion to its parent body.

@export var stats: LocomotionStats

# Must remain a direct child of the body whose velocity it updates.
@onready var _body: CharacterBody2D = get_parent()


## Wind shifts the target velocity so braking does not fight an added force.
func ground_update(delta: float, axis: float, wind_x: float = 0.0) -> void:
	var drift := ground_drift(wind_x)
	var target := axis * stats.move_speed * headwind_factor(axis, wind_x) + drift
	if is_zero_approx(axis):
		_body.velocity.x = move_toward(_body.velocity.x, drift, stats.deceleration * delta)
	elif is_zero_approx(_body.velocity.x) or signf(_body.velocity.x) == signf(axis):
		_body.velocity.x = move_toward(_body.velocity.x, target, stats.acceleration * delta)
	else:
		_body.velocity.x = move_toward(_body.velocity.x, target, stats.deceleration * delta)

func air_update(delta: float, axis: float, wind_x: float = 0.0) -> void:
	var drift := wind_x * stats.air_wind
	if is_zero_approx(axis):
		_body.velocity.x = move_toward(_body.velocity.x, drift, stats.deceleration * stats.air_brakes * delta)
	else:
		_body.velocity.x = move_toward(_body.velocity.x, axis * stats.move_speed + drift, stats.acceleration * stats.air_control * delta)

## Applies vertical wind acceleration; call after gravity.
func lift_update(delta: float, wind_y: float) -> void:
	_body.velocity.y += wind_y * stats.wind_lift * delta

## The share of move speed left walking along `axis` into `wind_x`, 0..1: a headwind under the deadzone still slows the
## step, so a lean never runs at full speed.
func headwind_factor(axis: float, wind_x: float) -> float:
	if is_zero_approx(axis) or is_zero_approx(wind_x) or signf(axis) == signf(wind_x) or stats.wind_deadzone <= 0.0:
		return 1.0
	return 1.0 - stats.headwind_slow * minf(absf(wind_x) / stats.wind_deadzone, 1.0)

## Returns ground drift after applying the wind deadzone and grip.
func ground_drift(wind_x: float) -> float:
	var excess := maxf(absf(wind_x) - stats.wind_deadzone, 0.0)
	return signf(wind_x) * excess * stats.wind_grip
