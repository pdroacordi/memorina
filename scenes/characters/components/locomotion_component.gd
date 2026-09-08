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


func ground_update(delta: float, axis: float) -> void:
	if is_zero_approx(axis):
		_body.velocity.x = move_toward(_body.velocity.x, 0.0, stats.deceleration * delta)
	elif is_zero_approx(_body.velocity.x) or signf(_body.velocity.x) == signf(axis):
		_body.velocity.x = move_toward(_body.velocity.x, axis * stats.move_speed, stats.acceleration * delta)
	else:
		_body.velocity.x = move_toward(_body.velocity.x, axis * stats.move_speed, stats.deceleration * delta)

func air_update(delta: float, axis: float) -> void:
	if is_zero_approx(axis):
		_body.velocity.x = move_toward(_body.velocity.x, 0.0, stats.deceleration * stats.air_brakes * delta)
	else:
		_body.velocity.x = move_toward(_body.velocity.x, axis * stats.move_speed, stats.acceleration * stats.air_control * delta)
