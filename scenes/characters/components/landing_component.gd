class_name LandingComponent
extends Node
## Detects hard landings and owns the recovery lockout that follows. Must be
## driven AFTER move_and_slide(), because that is what refreshes is_on_floor().

signal hard_landed(position: Vector2, impact_speed: float)

@export var stats: LandingStats

var _last_fall_speed: float = 0.0
var _was_on_floor: bool = true
var _just_landed: bool = false
var _recovery_timer: float = 0.0

# Always a direct child of the body it drives, matching the existing
# $PlayerInput / $Hurtbox idiom in this codebase; an exported NodePath would
# only add an inspector-reassignable foot-gun with no swappable-target use case.
@onready var _body: Character = get_parent()


func tick_timer(delta: float, on_floor: bool) -> void:
	if _recovery_timer > 0.0:
		_recovery_timer = _recovery_timer - delta if on_floor else 0.0

func sample_fall_speed(vertical_velocity: float) -> void:
	_last_fall_speed = maxf(vertical_velocity, 0.0)

## `on_floor` is a PARAMETER rather than a fresh is_on_floor() read: the
## caller reads it after move_and_slide(), and passing it in makes that
## ordering requirement explicit instead of hidden inside this method.
func check_landing(on_floor: bool) -> void:
	_just_landed = on_floor and not _was_on_floor
	if _just_landed and _last_fall_speed >= stats.hard_land_speed:
		_recovery_timer = stats.hard_land_time
		hard_landed.emit(_body.global_position, _last_fall_speed)
	_was_on_floor = on_floor

## Cuts the recovery short for something that outranks a heavy landing.
func cancel_recovery() -> void:
	_recovery_timer = 0.0

func is_recovering() -> bool:
	return _recovery_timer > 0.0

## True only on the physics frame the character touched down.
func just_landed() -> bool:
	return _just_landed
