class_name LocomotionComponent
extends Node
## Drives horizontal movement for the CharacterBody2D it is a child of; the
## owner decides WHEN to call these (ground vs air), the component only
## decides HOW the velocity changes.

@export var stats: LocomotionStats

# Always a direct child of the body it drives, matching the existing
# $PlayerInput / $Hurtbox idiom in this codebase; an exported NodePath would
# only add an inspector-reassignable foot-gun with no swappable-target use case.
@onready var _body: CharacterBody2D = get_parent()


## `wind_x` is the horizontal air the body stands in (Character.carry()): the
## body steers toward its input speed plus what the wind makes of it, so wind
## shifts the target rather than adding a force the brakes would fight.
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

## Vertical air (an updraft, the gale near its origin) as acceleration, for
## an airborne body. Call after gravity.
func lift_update(delta: float, wind_y: float) -> void:
	_body.velocity.y += wind_y * stats.wind_lift * delta

## What a wind does to feet on the ground: nothing below the deadzone, then a
## slide at wind_grip of the excess.
func ground_drift(wind_x: float) -> float:
	var excess := maxf(absf(wind_x) - stats.wind_deadzone, 0.0)
	return signf(wind_x) * excess * stats.wind_grip
